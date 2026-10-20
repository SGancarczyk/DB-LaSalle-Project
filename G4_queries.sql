-- G_queries.sql
-- Paris 2024 Olympic Games — Queries and Triggers
-- Author: Stanislaw Gancarczyk
-- Databases 2025-2026, La Salle - Universitat Ramon Llull
--
-- Idempotent. Run after G_import_part2_insert.sql.
--
-- Data limitations noted in report:
--   Q4/Q13: AVG_AGE null — AthleteCompetesInEvent contains medallists only.
--   Q17:    Empty result — no athlete won a medal on their birthday in this dataset.
--   Q25:    avg_weight null — weight not recorded in CSV for these basketball players.
--   Q26:    All sponsors from medal-winning countries (Mockaroo dataset limitation).
--   Q30:    Only 19 of 1021 tech officials have birth_date in source CSV.


-- Fix Person.birth_date for technical officials (19 records with dates in CSV).
-- Oracle Data Load auto-converts dates to 'DD-MON-RR HH.MI.SS.FF9 AM'.
UPDATE Person p
SET birth_date = (
    SELECT CAST(TO_TIMESTAMP(TRIM(tt.birth_date), 'DD-MON-RR HH.MI.SS.FF9 AM') AS DATE)
    FROM TEMP_TECH_OFFICIALS tt
    WHERE TRIM(tt.code) = TO_CHAR(p.code)
      AND tt.birth_date IS NOT NULL
      AND TRIM(tt.birth_date) != ''
      AND TRIM(tt.birth_date) != 'nan'
      AND LENGTH(TRIM(tt.birth_date)) > 10
)
WHERE p.birth_date IS NULL
  AND EXISTS (SELECT 1 FROM TechnicalOfficial t WHERE t.code = p.code)
  AND EXISTS (
      SELECT 1 FROM TEMP_TECH_OFFICIALS tt
      WHERE TRIM(tt.code) = TO_CHAR(p.code)
        AND tt.birth_date IS NOT NULL
        AND TRIM(tt.birth_date) != ''
        AND TRIM(tt.birth_date) != 'nan'
        AND LENGTH(TRIM(tt.birth_date)) > 10
  );
COMMIT;


-- Q1: Athletes with more than 2 gold medals in a single sport
SELECT p.name AS athlete_name, s.sport_name AS sport,
       COUNT(awm.medal_code) AS gold_medals
FROM AthleteWinsMedal awm
JOIN Medal  m ON awm.medal_code = m.medal_code AND m.medal_type = 'Gold Medal'
JOIN Event  e ON awm.event_tag  = e.event_tag
JOIN Sport  s ON e.sport_code   = s.sport_code
JOIN Person p ON awm.athlete_code = p.code
GROUP BY p.name, s.sport_name
HAVING COUNT(awm.medal_code) > 2
ORDER BY gold_medals DESC, athlete_name;


-- Q2: Total sponsorship for countries with at least one medal
SELECT c.country AS country_name, SUM(sp.sponsorship_budget) AS total_sponsorship
FROM Sponsor sp
JOIN Country c ON sp.country_code = c.country_code
WHERE sp.country_code IN (
    SELECT DISTINCT a.country_code
    FROM AthleteWinsMedal awm JOIN Athlete a ON awm.athlete_code = a.code
)
GROUP BY c.country
ORDER BY total_sponsorship DESC;


-- Q3: Coaches training a team in a sport that also has individual events
-- Double EXISTS: sport must have both TEAM and non-TEAM events simultaneously.
SELECT DISTINCT p.name AS coach_name, co.function AS coach_function,
       s.sport_name AS sport, t.team_name AS team_trained
FROM Coach co
JOIN Person          p   ON co.code       = p.code
JOIN CoachTrainsTeam ctt ON co.code       = ctt.coach_code
JOIN Team            t   ON ctt.team_code = t.team_code
JOIN CoachWorksInSport cws ON co.code     = cws.coach_code
JOIN Sport           s   ON cws.sport_code = s.sport_code
WHERE EXISTS (
    SELECT 1 FROM Event e1
    WHERE e1.sport_code = s.sport_code AND UPPER(e1.event_name) LIKE '%TEAM%'
)
AND EXISTS (
    SELECT 1 FROM Event e2
    WHERE e2.sport_code = s.sport_code AND UPPER(e2.event_name) NOT LIKE '%TEAM%'
)
ORDER BY s.sport_name, p.name
FETCH FIRST 30 ROWS ONLY;


-- Q4: Average age of female athletes in Artistic Gymnastics
-- Returns null — AthleteCompetesInEvent contains medallists only (see header note).
SELECT ROUND(AVG(MONTHS_BETWEEN(DATE '2024-07-26', TRUNC(p.birth_date)) / 12), 2) AS avg_age_years,
       COUNT(DISTINCT a.code) AS athlete_count
FROM Athlete a
JOIN Person p ON a.code = p.code
WHERE p.gender = 'Female'
  AND p.birth_date IS NOT NULL
  AND EXISTS (
      SELECT 1 FROM AthleteCompetesInEvent ace
      JOIN Event e ON ace.event_tag = e.event_tag
      JOIN Sport s ON e.sport_code  = s.sport_code
      WHERE ace.athlete_code = a.code AND s.sport_name = 'Artistic Gymnastics'
  );


-- Q5: Top 5 venues by number of distinct events hosted
-- ROWNUM applied after ORDER BY requires the two-level subquery structure.
SELECT ranked.*
FROM (
    SELECT v.venue_name,
           COUNT(DISTINCT s.event_tag) AS total_events,
           COUNT(s.schedule_id)        AS total_sessions
    FROM Schedule s JOIN Venue v ON s.venue_tag = v.venue_tag
    WHERE s.event_tag IS NOT NULL
    GROUP BY v.venue_name
    ORDER BY total_events DESC
) ranked
WHERE ROWNUM <= 5;


-- Q6: Technical officials from the International Gymnastics Federation
SELECT o.organisation_long AS federation_name, COUNT(t.code) AS official_count
FROM TechnicalOfficial t
JOIN Organisation o ON t.organisation_code = o.organisation_code
WHERE o.organisation_code = 'FIG'
GROUP BY o.organisation_long;


-- Q7: Top 10 countries by coach-to-athlete ratio
-- NULLIF prevents division by zero. Inline views aggregate before joining.
SELECT c.country AS country_name,
       coach_counts.n_coaches, athlete_counts.n_athletes,
       ROUND(coach_counts.n_coaches / NULLIF(athlete_counts.n_athletes, 0), 4) AS coach_athlete_ratio
FROM Country c
JOIN (SELECT country_code, COUNT(*) AS n_coaches  FROM Coach   GROUP BY country_code) coach_counts
  ON c.country_code = coach_counts.country_code
JOIN (SELECT country_code, COUNT(*) AS n_athletes FROM Athlete GROUP BY country_code) athlete_counts
  ON c.country_code = athlete_counts.country_code
ORDER BY coach_athlete_ratio DESC
FETCH FIRST 10 ROWS ONLY;


-- Q8: Athletes born in a different country than the one they represent
-- NOT LIKE on both short and long country name for case-insensitive matching.
SELECT p.name AS athlete_name, a.birth_place,
       c.country AS representing_country, c.country_code
FROM Athlete a
JOIN Person  p ON a.code = p.code
JOIN Country c ON a.country_code = c.country_code
WHERE a.birth_place IS NOT NULL
  AND NOT (
      UPPER(a.birth_place) LIKE '%' || UPPER(c.country) || '%'
      OR UPPER(a.birth_place) LIKE '%' || UPPER(c.country_long) || '%'
  )
ORDER BY c.country, p.name
FETCH FIRST 50 ROWS ONLY;


-- Q9: Finance sponsors of the top 5 medal-winning countries
SELECT DISTINCT sp.company_name, sp.industry,
       c.country AS sponsor_home_country, sp.sponsorship_budget
FROM Sponsor sp
JOIN Country c ON sp.country_code = c.country_code
WHERE sp.industry = 'Finance'
  AND (
      sp.country_code IN (
          SELECT country_code FROM (
              SELECT a.country_code, COUNT(*) AS medals
              FROM AthleteWinsMedal awm JOIN Athlete a ON awm.athlete_code = a.code
              GROUP BY a.country_code ORDER BY medals DESC
          ) WHERE ROWNUM <= 5
      )
      OR EXISTS (
          SELECT 1 FROM SponsorSponsorsCountry ssc
          WHERE ssc.sponsor_id = sp.sponsor_id
            AND ssc.country_code IN (
                SELECT country_code FROM (
                    SELECT a.country_code, COUNT(*) AS medals
                    FROM AthleteWinsMedal awm JOIN Athlete a ON awm.athlete_code = a.code
                    GROUP BY a.country_code ORDER BY medals DESC
                ) WHERE ROWNUM <= 5
            )
      )
  )
ORDER BY sp.sponsorship_budget DESC;


-- Q10: Most common function among Water Polo technical officials
SELECT to2.function, COUNT(*) AS official_count
FROM TechnicalOfficial to2
JOIN TechOfficialOfficiatesInSport tois ON to2.code = tois.tech_code
JOIN Sport s ON tois.sport_code = s.sport_code
WHERE UPPER(s.sport_name) LIKE '%WATER POLO%'
GROUP BY to2.function
ORDER BY official_count DESC
FETCH FIRST 1 ROWS ONLY;


-- Q11: Country with the most medals
SELECT c.country AS country_name, c.country_code, COUNT(*) AS total_medals
FROM AthleteWinsMedal awm
JOIN Athlete a ON awm.athlete_code = a.code
JOIN Country c ON a.country_code = c.country_code
GROUP BY c.country, c.country_code
ORDER BY total_medals DESC
FETCH FIRST 1 ROWS ONLY;


-- Q12: Coaches of the top medal-winning country
-- Inner ROWNUM subquery resolves the country dynamically.
SELECT DISTINCT p.name AS coach_name, co.function AS coach_role, s.sport_name AS sport
FROM Coach co
JOIN Person          p   ON co.code       = p.code
JOIN CoachTrainsTeam ctt ON co.code       = ctt.coach_code
JOIN Team            t   ON ctt.team_code = t.team_code
JOIN CoachWorksInSport cws ON co.code     = cws.coach_code
JOIN Sport           s   ON cws.sport_code = s.sport_code
WHERE t.country_code = (
    SELECT country_code FROM (
        SELECT a.country_code, COUNT(*) AS total_medals
        FROM AthleteWinsMedal awm JOIN Athlete a ON awm.athlete_code = a.code
        GROUP BY a.country_code ORDER BY total_medals DESC
    ) WHERE ROWNUM = 1
)
ORDER BY s.sport_name, p.name;


-- Q13: Top 3 sports with youngest athletes on average
-- Empty result — same AthleteCompetesInEvent limitation as Q4.
SELECT ranked.*
FROM (
    SELECT s.sport_name,
           ROUND(AVG(MONTHS_BETWEEN(DATE '2024-07-26', TRUNC(p.birth_date)) / 12), 2) AS avg_age,
           COUNT(DISTINCT a.code) AS athlete_count
    FROM Athlete a
    JOIN Person  p ON a.code = p.code
    JOIN AthleteCompetesInEvent ace ON ace.athlete_code = a.code
    JOIN Event   e ON ace.event_tag = e.event_tag
    JOIN Sport   s ON e.sport_code  = s.sport_code
    WHERE p.birth_date IS NOT NULL
    GROUP BY s.sport_name
    ORDER BY avg_age ASC
) ranked
WHERE ROWNUM <= 3;


-- Q14: Athletes competing in more than one sport
SELECT p.name AS athlete_name, COUNT(DISTINCT e.sport_code) AS sport_count
FROM AthleteCompetesInEvent ace
JOIN Athlete a ON ace.athlete_code = a.code
JOIN Person  p ON a.code = p.code
JOIN Event   e ON ace.event_tag = e.event_tag
GROUP BY p.name, a.code
HAVING COUNT(DISTINCT e.sport_code) > 1
ORDER BY sport_count DESC, p.name;


-- Q15: Healthcare sponsors of countries with more than 100 athletes
SELECT sp.company_name, sp.industry, c.country AS home_country, sp.sponsorship_budget
FROM Sponsor sp
JOIN Country c ON sp.country_code = c.country_code
WHERE sp.industry = 'Healthcare'
  AND sp.country_code IN (
      SELECT country_code FROM Athlete GROUP BY country_code HAVING COUNT(*) > 100
  )
ORDER BY sp.sponsorship_budget DESC;


-- Q16: Coaches whose country won no medals in their sport
-- Correlated NOT EXISTS checks both country and sport simultaneously.
SELECT DISTINCT p.name AS coach_name, co.function, c.country AS country, s.sport_name AS sport
FROM Coach co
JOIN Person  p ON co.code = p.code
JOIN Country c ON co.country_code = c.country_code
JOIN CoachWorksInSport cws ON co.code = cws.coach_code
JOIN Sport   s ON cws.sport_code = s.sport_code
WHERE NOT EXISTS (
    SELECT 1 FROM AthleteWinsMedal awm
    JOIN Athlete a ON awm.athlete_code = a.code
    JOIN Event   e ON awm.event_tag = e.event_tag
    WHERE a.country_code = co.country_code AND e.sport_code = cws.sport_code
)
ORDER BY c.country, s.sport_name
FETCH FIRST 50 ROWS ONLY;


-- Q17: Athletes who won a medal on their birthday
-- TRUNC removes sub-day precision before EXTRACT to ensure correct comparison.
-- Empty result — no coincidence in this dataset (valid answer, not an error).
SELECT p.name AS athlete_name, TRUNC(p.birth_date) AS birth_date,
       e.event_name, TRUNC(awm.medal_date) AS medal_date, m.medal_type
FROM AthleteWinsMedal awm
JOIN Athlete a ON awm.athlete_code = a.code
JOIN Person  p ON a.code = p.code
JOIN Event   e ON awm.event_tag = e.event_tag
JOIN Medal   m ON awm.medal_code = m.medal_code
WHERE p.birth_date IS NOT NULL AND awm.medal_date IS NOT NULL
  AND EXTRACT(MONTH FROM TRUNC(awm.medal_date)) = EXTRACT(MONTH FROM TRUNC(p.birth_date))
  AND EXTRACT(DAY   FROM TRUNC(awm.medal_date)) = EXTRACT(DAY   FROM TRUNC(p.birth_date))
ORDER BY p.name;


-- Q18: Athletes in ONLY team events vs ONLY individual events
SELECT 'Only Team Events' AS category, COUNT(DISTINCT athlete_code) AS athlete_count
FROM AthleteCompetesInEvent ace JOIN Event e ON ace.event_tag = e.event_tag
WHERE UPPER(e.event_name) LIKE '%TEAM%'
  AND ace.athlete_code NOT IN (
      SELECT DISTINCT ace2.athlete_code FROM AthleteCompetesInEvent ace2
      JOIN Event e2 ON ace2.event_tag = e2.event_tag
      WHERE UPPER(e2.event_name) NOT LIKE '%TEAM%'
  )
UNION ALL
SELECT 'Only Individual Events', COUNT(DISTINCT athlete_code)
FROM AthleteCompetesInEvent ace JOIN Event e ON ace.event_tag = e.event_tag
WHERE UPPER(e.event_name) NOT LIKE '%TEAM%'
  AND ace.athlete_code NOT IN (
      SELECT DISTINCT ace2.athlete_code FROM AthleteCompetesInEvent ace2
      JOIN Event e2 ON ace2.event_tag = e2.event_tag
      WHERE UPPER(e2.event_name) LIKE '%TEAM%'
  );


-- Q19: Venues that hosted only one sport
-- MIN(sport_name) used because Oracle requires non-aggregated columns in GROUP BY;
-- after HAVING = 1 there is exactly one sport per retained venue.
SELECT v.venue_name, MIN(s.sport_name) AS single_sport_hosted,
       COUNT(DISTINCT s.sport_code) AS sport_count
FROM Schedule sc
JOIN Venue v ON sc.venue_tag = v.venue_tag
JOIN Event e ON sc.event_tag = e.event_tag
JOIN Sport s ON e.sport_code = s.sport_code
GROUP BY v.venue_name
HAVING COUNT(DISTINCT s.sport_code) = 1
ORDER BY v.venue_name;


-- Q20: Female coaches assigned to male teams
SELECT DISTINCT c.country AS country_name, p.name AS female_coach_name,
       t.team_name AS male_team_name, s.sport_name
FROM Coach co
JOIN Person          p   ON co.code         = p.code
JOIN Country         c   ON co.country_code = c.country_code
JOIN CoachTrainsTeam ctt ON co.code         = ctt.coach_code
JOIN Team            t   ON ctt.team_code   = t.team_code
JOIN CoachWorksInSport cws ON co.code       = cws.coach_code
JOIN Sport           s   ON cws.sport_code  = s.sport_code
WHERE p.gender = 'Female' AND t.team_gender = 'M'
ORDER BY c.country, p.name;


-- Q21: Number of countries with female coaches on male teams
SELECT COUNT(DISTINCT c.country_code) AS countries_with_female_coaches_on_male_teams
FROM Coach co
JOIN Person          p   ON co.code       = p.code
JOIN CoachTrainsTeam ctt ON co.code       = ctt.coach_code
JOIN Team            t   ON ctt.team_code = t.team_code
JOIN Country         c   ON co.country_code = c.country_code
WHERE p.gender = 'Female' AND t.team_gender = 'M';


-- Q22: Technical officials in sports where France won gold
SELECT DISTINCT p.name AS official_name, to2.function, s.sport_name, o.organisation
FROM TechnicalOfficial to2
JOIN Person       p  ON to2.code              = p.code
JOIN Organisation o  ON to2.organisation_code = o.organisation_code
JOIN TechOfficialOfficiatesInSport tois ON to2.code = tois.tech_code
JOIN Sport        s  ON tois.sport_code       = s.sport_code
WHERE s.sport_code IN (
    SELECT DISTINCT e.sport_code
    FROM AthleteWinsMedal awm
    JOIN Athlete a ON awm.athlete_code = a.code
    JOIN Medal   m ON awm.medal_code   = m.medal_code
    JOIN Event   e ON awm.event_tag    = e.event_tag
    WHERE a.country_code = 'FRA' AND m.medal_type = 'Gold Medal'
)
ORDER BY s.sport_name, p.name
FETCH FIRST 50 ROWS ONLY;


-- Q23: Athletes with medals in both team and individual events
SELECT DISTINCT p.name AS athlete_name, c.country AS country
FROM AthleteWinsMedal awm
JOIN Athlete a ON awm.athlete_code = a.code
JOIN Person  p ON a.code = p.code
JOIN Country c ON a.country_code = c.country_code
WHERE EXISTS (
    SELECT 1 FROM AthleteWinsMedal awm2
    JOIN Event e2 ON awm2.event_tag = e2.event_tag
    WHERE awm2.athlete_code = awm.athlete_code AND UPPER(e2.event_name) LIKE '%TEAM%'
)
AND EXISTS (
    SELECT 1 FROM AthleteWinsMedal awm3
    JOIN Event e3 ON awm3.event_tag = e3.event_tag
    WHERE awm3.athlete_code = awm.athlete_code AND UPPER(e3.event_name) NOT LIKE '%TEAM%'
)
ORDER BY c.country, p.name;


-- Q24: Events finished before 25th July 2024
-- TIMESTAMP literal with +00:00 matches TIMESTAMP WITH TIME ZONE column type.
SELECT COUNT(DISTINCT s.event_tag) AS events_finished_before_july_25
FROM Schedule s
WHERE s.status = 'FINISHED'
  AND s.end_date < TIMESTAMP '2024-07-25 00:00:00 +00:00';


-- Q25: Average height/weight of male basketball medalists vs non-medalists
-- Non-medalists identified via AthleteMemberOfTeam (team_code LIKE 'BKB%').
-- avg_weight null for both groups — not recorded in source CSV.
SELECT 'Medalist' AS category,
    COUNT(DISTINCT a.code) AS athlete_count,
    ROUND(AVG(a.height), 2) AS avg_height_cm,
    ROUND(AVG(NULLIF(a.weight, 0)), 2) AS avg_weight_kg
FROM Athlete a JOIN Person p ON a.code = p.code
WHERE p.gender = 'Male' AND a.height IS NOT NULL
  AND EXISTS (
      SELECT 1 FROM AthleteWinsMedal awm
      JOIN Event e ON awm.event_tag = e.event_tag
      JOIN Sport s ON e.sport_code  = s.sport_code
      WHERE awm.athlete_code = a.code AND s.sport_name = 'Basketball')
UNION ALL
SELECT 'Non-Medalist',
    COUNT(DISTINCT a.code),
    ROUND(AVG(a.height), 2),
    ROUND(AVG(NULLIF(a.weight, 0)), 2)
FROM Athlete a JOIN Person p ON a.code = p.code
JOIN AthleteMemberOfTeam amot ON amot.athlete_code = a.code
WHERE p.gender = 'Male' AND a.height IS NOT NULL
  AND amot.team_code LIKE 'BKB%'
  AND NOT EXISTS (
      SELECT 1 FROM AthleteWinsMedal awm
      JOIN Event e ON awm.event_tag = e.event_tag
      JOIN Sport s ON e.sport_code  = s.sport_code
      WHERE awm.athlete_code = a.code AND s.sport_name = 'Basketball');


-- Q26: Countries receiving most sponsorship with medal count
-- LEFT JOIN ensures sponsor countries with no medals still appear (NVL handles NULL).
SELECT c.country AS country_name,
       SUM(sp.sponsorship_budget) AS total_sponsorship,
       NVL(medal_counts.total_medals, 0) AS total_medals,
       CASE WHEN NVL(medal_counts.total_medals, 0) = 0
            THEN 'No medals' ELSE 'Has medals' END AS medal_status
FROM Sponsor sp
JOIN Country c ON sp.country_code = c.country_code
LEFT JOIN (
    SELECT a.country_code, COUNT(*) AS total_medals
    FROM AthleteWinsMedal awm JOIN Athlete a ON awm.athlete_code = a.code
    GROUP BY a.country_code
) medal_counts ON medal_counts.country_code = c.country_code
GROUP BY c.country, medal_counts.total_medals
ORDER BY total_sponsorship DESC
FETCH FIRST 10 ROWS ONLY;


-- Q27: Coaches whose athletes come from more than one country
SELECT p_coach.name AS coach_name,
       COUNT(DISTINCT a.country_code) AS country_count,
       COUNT(DISTINCT a.code) AS athlete_count
FROM Coach co
JOIN Person            p_coach ON co.code      = p_coach.code
JOIN CoachWorksInSport cws     ON co.code      = cws.coach_code
JOIN Event             e       ON e.sport_code = cws.sport_code
JOIN AthleteCompetesInEvent ace ON ace.event_tag   = e.event_tag
JOIN Athlete           a        ON ace.athlete_code = a.code
GROUP BY p_coach.name, co.code
HAVING COUNT(DISTINCT a.country_code) > 1
ORDER BY country_count DESC, athlete_count DESC
FETCH FIRST 20 ROWS ONLY;


-- Q28: Top 5 sports by number of different venues used
SELECT ranked.*
FROM (
    SELECT s.sport_name, COUNT(DISTINCT sc.venue_tag) AS venue_count
    FROM Schedule sc
    JOIN Event e ON sc.event_tag = e.event_tag
    JOIN Sport s ON e.sport_code = s.sport_code
    WHERE sc.venue_tag IS NOT NULL
    GROUP BY s.sport_name
    ORDER BY venue_count DESC
) ranked
WHERE ROWNUM <= 5;


-- Q29: Oldest athlete at Paris 2024
SELECT p.name AS athlete_name, TRUNC(p.birth_date) AS birth_date,
       a.birth_place, c.country AS representing_country,
       TRUNC(MONTHS_BETWEEN(DATE '2024-07-26', TRUNC(p.birth_date)) / 12) AS age_at_games
FROM Athlete a
JOIN Person  p ON a.code = p.code
JOIN Country c ON a.country_code = c.country_code
WHERE p.birth_date = (
    SELECT MIN(p2.birth_date) FROM Person p2
    JOIN Athlete a2 ON a2.code = p2.code
    WHERE p2.birth_date IS NOT NULL
);


-- Q30/31: Oldest technical official
-- Only 19 of 1021 officials have birth_date — returns oldest among those 19.
SELECT p.name AS official_name, TRUNC(p.birth_date) AS birth_date,
       TRUNC(MONTHS_BETWEEN(DATE '2024-07-26', TRUNC(p.birth_date)) / 12) AS age_at_games,
       o.organisation_code, o.organisation_long AS organisation_name
FROM TechnicalOfficial t
JOIN Person       p ON t.code = p.code
JOIN Organisation o ON t.organisation_code = o.organisation_code
WHERE p.birth_date IS NOT NULL
ORDER BY TRUNC(p.birth_date) ASC
FETCH FIRST 1 ROWS ONLY;


-- Q32: Countries with more than 5 coaches
SELECT c.country AS country_name, COUNT(co.code) AS total_coaches
FROM Coach co JOIN Country c ON co.country_code = c.country_code
GROUP BY c.country, c.country_code
HAVING COUNT(co.code) > 5
ORDER BY total_coaches DESC;


-- Bonus: Medal standings using RANK() window function
SELECT * FROM (
    SELECT c.country,
        COUNT(CASE WHEN m.medal_type = 'Gold Medal'   THEN 1 END) AS gold,
        COUNT(CASE WHEN m.medal_type = 'Silver Medal' THEN 1 END) AS silver,
        COUNT(CASE WHEN m.medal_type = 'Bronze Medal' THEN 1 END) AS bronze,
        COUNT(*) AS total,
        RANK() OVER (
            ORDER BY
                COUNT(CASE WHEN m.medal_type = 'Gold Medal'   THEN 1 END) DESC,
                COUNT(CASE WHEN m.medal_type = 'Silver Medal' THEN 1 END) DESC,
                COUNT(CASE WHEN m.medal_type = 'Bronze Medal' THEN 1 END) DESC
        ) AS standing
    FROM AthleteWinsMedal awm
    JOIN Athlete a ON awm.athlete_code = a.code
    JOIN Country c ON a.country_code   = c.country_code
    JOIN Medal   m ON awm.medal_code   = m.medal_code
    GROUP BY c.country
)
WHERE standing <= 10
ORDER BY standing;


-- Auxiliary tables for triggers
DROP TABLE Medal_Audit        PURGE;
DROP TABLE Athlete_Delete_Log PURGE;

CREATE TABLE Medal_Audit (
    audit_id        NUMBER GENERATED ALWAYS AS IDENTITY,
    athlete_code    NUMBER(10),
    athlete_name    VARCHAR2(100),
    medal_type      VARCHAR2(20),
    event_tag       VARCHAR2(80),
    awarded_on      DATE,
    inserted_at     TIMESTAMP DEFAULT SYSTIMESTAMP,
    CONSTRAINT pk_medal_audit PRIMARY KEY (audit_id)
);

CREATE TABLE Athlete_Delete_Log (
    log_id          NUMBER GENERATED ALWAYS AS IDENTITY,
    country_code    VARCHAR2(3),
    country_name    VARCHAR2(100),
    athlete_count   NUMBER,
    attempted_at    TIMESTAMP DEFAULT SYSTIMESTAMP,
    CONSTRAINT pk_delete_log PRIMARY KEY (log_id)
);


-- Trigger 1: Reject invalid athlete measurements on INSERT
-- Valid ranges from Paris 2024 data: height 140-230 cm, weight 30-200 kg.
CREATE OR REPLACE TRIGGER trg_validate_athlete_measurements
BEFORE INSERT ON Athlete
FOR EACH ROW
BEGIN
    IF :NEW.height IS NOT NULL THEN
        IF :NEW.height < 140 OR :NEW.height > 230 THEN
            RAISE_APPLICATION_ERROR(-20001,
                'Invalid height: ' || :NEW.height ||
                ' cm. Must be between 140 and 230 cm for Olympic athletes.');
        END IF;
    END IF;
    IF :NEW.weight IS NOT NULL THEN
        IF :NEW.weight < 30 OR :NEW.weight > 200 THEN
            RAISE_APPLICATION_ERROR(-20002,
                'Invalid weight: ' || :NEW.weight ||
                ' kg. Must be between 30 and 200 kg for Olympic athletes.');
        END IF;
    END IF;
END;
/

-- Test Trigger 1
INSERT INTO Person (code, name, gender, birth_date) VALUES (9999001, 'TEST Athlete Valid', 'Male', DATE '2000-01-01');
INSERT INTO Athlete (code, name_short, height, weight, birth_place, country_code) VALUES (9999001, 'T. VALID', 180.5, 75.0, 'Warsaw', 'POL');
INSERT INTO Person (code, name, gender, birth_date) VALUES (9999002, 'TEST Athlete Invalid', 'Male', DATE '2000-01-01');
INSERT INTO Athlete (code, name_short, height, weight, birth_place, country_code) VALUES (9999002, 'T. INVALID', 50.0, 75.0, 'Warsaw', 'POL');
DELETE FROM Athlete WHERE code IN (9999001, 9999002);
DELETE FROM Person  WHERE code IN (9999001, 9999002);
COMMIT;


-- Trigger 2: Audit every medal award in Medal_Audit
-- AFTER INSERT ensures only successfully committed rows are logged.
CREATE OR REPLACE TRIGGER trg_audit_medal_win
AFTER INSERT ON AthleteWinsMedal
FOR EACH ROW
DECLARE
    v_athlete_name VARCHAR2(100);
    v_medal_type   VARCHAR2(20);
BEGIN
    SELECT name       INTO v_athlete_name FROM Person WHERE code       = :NEW.athlete_code;
    SELECT medal_type INTO v_medal_type   FROM Medal  WHERE medal_code = :NEW.medal_code;
    INSERT INTO Medal_Audit (athlete_code, athlete_name, medal_type, event_tag, awarded_on)
    VALUES (:NEW.athlete_code, v_athlete_name, v_medal_type, :NEW.event_tag, :NEW.medal_date);
EXCEPTION WHEN NO_DATA_FOUND THEN NULL;
END;
/

-- Test Trigger 2
INSERT INTO Person (code, name, gender, birth_date) VALUES (9999003, 'TEST Medal Athlete', 'Male', DATE '1995-01-01');
INSERT INTO Athlete (code, name_short, height, weight, birth_place, country_code) VALUES (9999003, 'T. MEDAL', 180.0, 75.0, 'Warsaw', 'POL');
INSERT INTO AthleteCompetesInEvent (athlete_code, event_tag, start_date)
VALUES (9999003, (SELECT event_tag FROM Event WHERE ROWNUM = 1), DATE '2024-07-27');
INSERT INTO AthleteWinsMedal (medal_code, event_tag, athlete_code, medal_date)
VALUES (1, (SELECT event_tag FROM Event WHERE ROWNUM = 1), 9999003, DATE '2024-07-27');
SELECT athlete_name, medal_type, event_tag, awarded_on FROM Medal_Audit WHERE athlete_code = 9999003;
DELETE FROM AthleteWinsMedal       WHERE athlete_code = 9999003;
DELETE FROM AthleteCompetesInEvent WHERE athlete_code = 9999003;
DELETE FROM Athlete WHERE code = 9999003;
DELETE FROM Person  WHERE code = 9999003;
COMMIT;


-- Trigger 3: Block country_code UPDATE when athletes reference it
-- COMMIT not allowed in triggers (ORA-04092) — Oracle rolls back on error automatically.
CREATE OR REPLACE TRIGGER trg_protect_country_update
BEFORE UPDATE OF country_code ON Country
FOR EACH ROW
DECLARE
    v_athlete_count NUMBER;
BEGIN
    SELECT COUNT(*) INTO v_athlete_count FROM Athlete WHERE country_code = :OLD.country_code;
    IF v_athlete_count > 0 THEN
        RAISE_APPLICATION_ERROR(-20003,
            'Cannot change country_code from ''' || :OLD.country_code ||
            ''' to ''' || :NEW.country_code ||
            '''. ' || v_athlete_count ||
            ' athlete(s) reference this country. Update Athlete records first.');
    END IF;
END;
/

-- Test Trigger 3
UPDATE Country SET country_code = 'ZZZ' WHERE country_code = 'FRA';  -- should fail
UPDATE Country SET country_code = 'ZZY' WHERE country_code = 'CIS';  -- should succeed
SELECT country_code, country FROM Country WHERE country_code = 'ZZY';
ROLLBACK;
