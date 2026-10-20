-- G_import.sql
-- Paris 2024 Olympic Games — Data Import
-- Author: Stanislaw Gancarczyk
-- Databases 2025-2026, La Salle - Universitat Ramon Llull
--
-- This script must be run in two stages with a manual step in between:
--
-- STAGE 1: Run lines 1 to the STOP marker below (creates TEMP tables).
-- MANUAL:  Load each CSV into its TEMP table using the Data Load wizard.
-- STAGE 2: Run lines after the STOP marker (INSERT-SELECT to physical tables).
--
-- To run only part of this file in SQL Developer: select the lines and press F9.
--
-- Load order:
--   1. TEMP_NOCS           <- nocs.csv
--   2. TEMP_VENUES         <- venues.csv
--   3. TEMP_EVENTS         <- events.csv
--   4. TEMP_MEDALS         <- medals.csv
--   5. TEMP_ATHLETES       <- athletes.csv
--   6. TEMP_COACHES        <- coaches.csv
--   7. TEMP_TECH_OFFICIALS <- technical_officials.csv
--   8. TEMP_TEAMS          <- teams.csv
--   9. TEMP_SCHEDULES      <- schedules.csv
--  10. TEMP_MEDALLISTS     <- medallists.csv
--  11. TEMP_SPONSORS       <- sponsors.csv
--
-- Note: athletes.csv and coaches.csv contain columns named 'current' and 'function'
-- which are reserved words in Oracle. During Data Load, map these manually to
-- current_flag and function_col respectively.

DROP TABLE TEMP_NOCS           PURGE;
DROP TABLE TEMP_VENUES         PURGE;
DROP TABLE TEMP_EVENTS         PURGE;
DROP TABLE TEMP_ATHLETES       PURGE;
DROP TABLE TEMP_COACHES        PURGE;
DROP TABLE TEMP_TECH_OFFICIALS PURGE;
DROP TABLE TEMP_TEAMS          PURGE;
DROP TABLE TEMP_SCHEDULES      PURGE;
DROP TABLE TEMP_MEDALS         PURGE;
DROP TABLE TEMP_MEDALLISTS     PURGE;
DROP TABLE TEMP_SPONSORS       PURGE;


-- nocs.csv
CREATE TABLE TEMP_NOCS (
    code            VARCHAR2(10),
    country         VARCHAR2(100),
    country_long    VARCHAR2(200),
    tag             VARCHAR2(100),
    note            VARCHAR2(10)
);


-- venues.csv
-- sports column stores a Python list string e.g. "['Archery', 'Athletics']"
CREATE TABLE TEMP_VENUES (
    venue           VARCHAR2(200),
    sports          VARCHAR2(500),
    date_start      VARCHAR2(50),
    date_end        VARCHAR2(50),
    tag             VARCHAR2(100),
    url             VARCHAR2(300)
);


-- events.csv
-- tag is the sport-level tag; event_tag is generated during INSERT-SELECT in part2.
CREATE TABLE TEMP_EVENTS (
    event           VARCHAR2(200),
    tag             VARCHAR2(100),
    sport           VARCHAR2(100),
    sport_code      VARCHAR2(10),
    sport_url       VARCHAR2(300)
);


-- athletes.csv
-- current and function are Oracle reserved words, renamed current_flag / function_col.
-- Columns not used in the physical model (hobbies, hero, etc.) are still loaded
-- to preserve the original file structure as required.
-- VARCHAR2 sizes set to 1.5x the maximum observed value in the source file.
CREATE TABLE TEMP_ATHLETES (
    code                VARCHAR2(20),
    current_flag        VARCHAR2(10),
    name                VARCHAR2(100),
    name_short          VARCHAR2(100),
    name_tv             VARCHAR2(100),
    gender              VARCHAR2(100),
    function_col        VARCHAR2(100),
    country_code        VARCHAR2(100),
    country             VARCHAR2(100),
    country_long        VARCHAR2(100),
    nationality         VARCHAR2(100),
    nationality_long    VARCHAR2(100),
    nationality_code    VARCHAR2(100),
    height              VARCHAR2(100),
    weight              VARCHAR2(100),
    disciplines         VARCHAR2(100),
    events              VARCHAR2(400),
    birth_date          VARCHAR2(100),
    birth_place         VARCHAR2(100),
    birth_country       VARCHAR2(100),
    residence_place     VARCHAR2(100),
    residence_country   VARCHAR2(100),
    nickname            VARCHAR2(600),
    hobbies             VARCHAR2(900),
    occupation          VARCHAR2(500),
    education           VARCHAR2(600),
    family              VARCHAR2(500),
    lang                VARCHAR2(200),
    coach               VARCHAR2(600),
    reason              VARCHAR2(1500),
    hero                VARCHAR2(1500),
    influence           VARCHAR2(1200),
    philosophy          VARCHAR2(1500),
    sporting_relatives  VARCHAR2(1500),
    ritual              VARCHAR2(1300),
    other_sports        VARCHAR2(1000)
);


-- coaches.csv
CREATE TABLE TEMP_COACHES (
    code            VARCHAR2(20),
    current_flag    VARCHAR2(10),
    name            VARCHAR2(200),
    gender          VARCHAR2(20),
    function_col    VARCHAR2(100),
    category        VARCHAR2(10),
    country_code    VARCHAR2(10),
    country         VARCHAR2(100),
    country_long    VARCHAR2(200),
    disciplines     VARCHAR2(500),
    events          VARCHAR2(500),
    birth_date      VARCHAR2(50)
);


-- technical_officials.csv
CREATE TABLE TEMP_TECH_OFFICIALS (
    code                VARCHAR2(20),
    current_flag        VARCHAR2(10),
    name                VARCHAR2(200),
    gender              VARCHAR2(20),
    function_col        VARCHAR2(100),
    category            VARCHAR2(10),
    organisation_code   VARCHAR2(20),
    organisation        VARCHAR2(100),
    organisation_long   VARCHAR2(200),
    disciplines         VARCHAR2(500),
    events              VARCHAR2(500),
    birth_date          VARCHAR2(50)
);


-- teams.csv
-- athletes_codes and coaches_codes store Python list strings e.g. "['1913366', '1913367']"
-- Parsed in part2 using PL/SQL with REGEXP_SUBSTR.
CREATE TABLE TEMP_TEAMS (
    code                VARCHAR2(50),
    current_flag        VARCHAR2(10),
    team                VARCHAR2(200),
    team_gender         VARCHAR2(5),
    country_code        VARCHAR2(10),
    country             VARCHAR2(100),
    country_long        VARCHAR2(200),
    discipline          VARCHAR2(100),
    disciplines_code    VARCHAR2(20),
    events              VARCHAR2(500),
    athletes            VARCHAR2(500),
    coaches             VARCHAR2(500),
    athletes_codes      VARCHAR2(4000),
    num_athletes        VARCHAR2(10),
    coaches_codes       VARCHAR2(4000),
    num_coaches         VARCHAR2(10)
);


-- schedules.csv
-- start_date/end_date format: '2024-07-24T15:00:00+02:00'
-- venue_code uses short codes (AQC, BCY) mapped to venue_tag slugs via DECODE() in part2.
CREATE TABLE TEMP_SCHEDULES (
    start_date              VARCHAR2(50),
    end_date                VARCHAR2(50),
    day                     VARCHAR2(50),
    status                  VARCHAR2(30),
    discipline              VARCHAR2(100),
    discipline_code         VARCHAR2(10),
    event                   VARCHAR2(200),
    event_medal             VARCHAR2(10),
    phase                   VARCHAR2(200),
    gender                  VARCHAR2(20),
    event_type              VARCHAR2(20),
    venue                   VARCHAR2(200),
    venue_code              VARCHAR2(10),
    location_description    VARCHAR2(200),
    location_code           VARCHAR2(10),
    url                     VARCHAR2(500)
);


-- medals.csv
-- Used only to populate the Medal reference table (3 rows: Gold, Silver, Bronze).
-- Full medal award records come from medallists.csv instead.
CREATE TABLE TEMP_MEDALS (
    medal_type      VARCHAR2(30),
    medal_code      VARCHAR2(5),
    medal_date      VARCHAR2(50),
    name            VARCHAR2(200),
    gender          VARCHAR2(20),
    discipline      VARCHAR2(100),
    event           VARCHAR2(200),
    event_type      VARCHAR2(20),
    url_event       VARCHAR2(500),
    code            VARCHAR2(20),
    country_code    VARCHAR2(10),
    country         VARCHAR2(100),
    country_long    VARCHAR2(200)
);


-- medallists.csv
-- Source for AthleteWinsMedal and AthleteCompetesInEvent.
CREATE TABLE TEMP_MEDALLISTS (
    medal_date          VARCHAR2(50),
    medal_type          VARCHAR2(30),
    medal_code          VARCHAR2(5),
    name                VARCHAR2(200),
    gender              VARCHAR2(20),
    country_code        VARCHAR2(10),
    country             VARCHAR2(100),
    country_long        VARCHAR2(200),
    nationality_code    VARCHAR2(10),
    nationality         VARCHAR2(100),
    nationality_long    VARCHAR2(200),
    team                VARCHAR2(200),
    team_gender         VARCHAR2(10),
    discipline          VARCHAR2(100),
    event               VARCHAR2(200),
    event_type          VARCHAR2(20),
    url_event           VARCHAR2(500),
    birth_date          VARCHAR2(50),
    code_athlete        VARCHAR2(20),
    code_team           VARCHAR2(50),
    is_medallist        VARCHAR2(10)
);


-- sponsors.csv (custom Mockaroo-generated file)
CREATE TABLE TEMP_SPONSORS (
    sponsor_id          VARCHAR2(20),
    company_name        VARCHAR2(200),
    industry            VARCHAR2(100),
    sponsorship_budget  VARCHAR2(30),
    country_code        VARCHAR2(10)
);


SELECT table_name FROM user_tables
WHERE table_name LIKE 'TEMP_%'
ORDER BY table_name;


-- =============================================================================
-- STOP HERE
-- Load all CSV files into their TEMP tables using the Data Load wizard.
-- After all 11 files are loaded, continue running from this point.
-- =============================================================================

-- Key conversions applied in the INSERT-SELECT statements below:
--   CAST(TO_TIMESTAMP(val, 'DD-MON-RR HH.MI.SS.FF9 AM') AS DATE)
--       Oracle Data Load converts ISO-8601 dates to NLS session timestamp format.
--   TO_TIMESTAMP_TZ(val, 'YYYY-MM-DD"T"HH24:MI:SSTZH:TZM')
--       For schedule timestamps with +02:00 timezone offset.
--   REGEXP_REPLACE(REPLACE(REPLACE(event, '+', 'plus'), '-', 'minus'), '[^a-zA-Z0-9]', '-')
--       Generates event_tag. plus/minus substitution avoids duplicate tags
--       for Judo Women +78kg and Women -78kg.
--   TRIM() applied to every column.


-- Clean all tables in reverse dependency order
DELETE FROM SponsorSponsorsCountry;
DELETE FROM TechOfficialOfficiatesInSport;
DELETE FROM CoachWorksInSport;
DELETE FROM AthleteCompetesInEvent;
DELETE FROM AthleteWinsMedal;
DELETE FROM AthleteMemberOfTeam;
DELETE FROM CoachTrainsTeam;
DELETE FROM Schedule;
DELETE FROM TechnicalOfficial;
DELETE FROM Coach;
DELETE FROM Athlete;
DELETE FROM Person;
DELETE FROM Team;
DELETE FROM Sponsor;
DELETE FROM Event;
DELETE FROM Venue;
DELETE FROM Medal;
DELETE FROM Sport;
DELETE FROM Organisation;
DELETE FROM Country;
COMMIT;

-- Reset Schedule sequence
DROP SEQUENCE schedule_seq;
CREATE SEQUENCE schedule_seq START WITH 1 INCREMENT BY 1 NOCACHE NOCYCLE;


-- 1. Country
-- code in nocs.csv maps to country_code (our PK).
INSERT INTO Country (country_code, country, country_long, tag, note)
SELECT TRIM(code), TRIM(country), TRIM(country_long), TRIM(tag), TRIM(note)
FROM TEMP_NOCS
WHERE code IS NOT NULL;
COMMIT;
SELECT 'Country' AS tbl, COUNT(*) AS cnt FROM Country;


-- 2. Organisation
-- Distinct organisations from technical_officials.csv.
-- Includes international federation codes (FIG, FIBA) not present in nocs.csv.
INSERT INTO Organisation (organisation_code, organisation, organisation_long)
SELECT DISTINCT TRIM(organisation_code), TRIM(organisation), TRIM(organisation_long)
FROM TEMP_TECH_OFFICIALS
WHERE organisation_code IS NOT NULL;
COMMIT;
SELECT 'Organisation' AS tbl, COUNT(*) AS cnt FROM Organisation;


-- 3. Sport
-- Each sport appears once per event in events.csv — DISTINCT collapses to 45 rows.
INSERT INTO Sport (sport_code, sport_name, sport_url)
SELECT DISTINCT TRIM(sport_code), TRIM(sport), TRIM(sport_url)
FROM TEMP_EVENTS
WHERE sport_code IS NOT NULL;
COMMIT;
SELECT 'Sport' AS tbl, COUNT(*) AS cnt FROM Sport;


-- 4. Medal
-- Manual insert — medal_description does not exist in source CSV.
INSERT INTO Medal (medal_code, medal_type, medal_description)
VALUES (1, 'Gold Medal',   'Awarded to the athlete(s) finishing in first place');
INSERT INTO Medal (medal_code, medal_type, medal_description)
VALUES (2, 'Silver Medal', 'Awarded to the athlete(s) finishing in second place');
INSERT INTO Medal (medal_code, medal_type, medal_description)
VALUES (3, 'Bronze Medal', 'Awarded to the athlete(s) finishing in third place');
COMMIT;
SELECT 'Medal' AS tbl, COUNT(*) AS cnt FROM Medal;


-- 5. Venue
-- date_start/date_end: extract YYYY-MM-DD portion from full ISO timestamp string.
INSERT INTO Venue (venue_tag, venue_name, date_start, date_end)
SELECT
    TRIM(tag),
    TRIM(venue),
    TO_DATE(SUBSTR(TRIM(date_start), 1, 10), 'YYYY-MM-DD'),
    TO_DATE(SUBSTR(TRIM(date_end),   1, 10), 'YYYY-MM-DD')
FROM TEMP_VENUES
WHERE tag IS NOT NULL;
COMMIT;
SELECT 'Venue' AS tbl, COUNT(*) AS cnt FROM Venue;


-- 6. Event
-- event_tag generated as sport_code + '-' + cleaned event name.
-- + replaced with 'plus', - replaced with 'minus' before REGEXP_REPLACE
-- to prevent duplicate tags for Judo Women +78kg / Women -78kg.
-- gender derived from event name via CASE WHEN.
INSERT INTO Event (event_tag, event_name, gender, sport_code)
SELECT
    TRIM(sport_code) || '-' ||
        REGEXP_REPLACE(
            REPLACE(REPLACE(TRIM(event), '+', 'plus'), '-', 'minus'),
        '[^a-zA-Z0-9]', '-') AS event_tag,
    TRIM(event),
    CASE
        WHEN UPPER(TRIM(event)) LIKE '%WOMEN%' THEN 'Women'
        WHEN UPPER(TRIM(event)) LIKE '%MEN%'   THEN 'Men'
        WHEN UPPER(TRIM(event)) LIKE '%MIXED%' THEN 'Mixed'
        ELSE 'Open'
    END,
    TRIM(sport_code)
FROM TEMP_EVENTS
WHERE sport_code IS NOT NULL AND event IS NOT NULL;
COMMIT;
SELECT 'Event' AS tbl, COUNT(*) AS cnt FROM Event;


-- 7. Person
-- UNION (not UNION ALL) across all three source files — deduplicates shared codes.
-- Oracle Data Load converts birth_date from YYYY-MM-DD to 'DD-MON-RR HH.MI.SS.FF9 AM'.
-- CAST(TO_TIMESTAMP(...) AS DATE) handles this format with 9-digit nanoseconds.
-- REGEXP_LIKE guards against non-numeric codes before TO_NUMBER().
INSERT INTO Person (code, name, gender, birth_date)
SELECT TO_NUMBER(TRIM(code)), TRIM(name), TRIM(gender),
    CASE WHEN birth_date IS NOT NULL AND TRIM(birth_date) != ''
         THEN CAST(TO_TIMESTAMP(TRIM(birth_date), 'DD-MON-RR HH.MI.SS.FF9 AM') AS DATE)
         ELSE NULL END
FROM TEMP_ATHLETES
WHERE code IS NOT NULL AND REGEXP_LIKE(TRIM(code), '^\d+$')
UNION
SELECT TO_NUMBER(TRIM(code)), TRIM(name), TRIM(gender),
    CASE WHEN birth_date IS NOT NULL AND TRIM(birth_date) != ''
         THEN CAST(TO_TIMESTAMP(TRIM(birth_date), 'DD-MON-RR HH.MI.SS.FF9 AM') AS DATE)
         ELSE NULL END
FROM TEMP_COACHES
WHERE code IS NOT NULL AND REGEXP_LIKE(TRIM(code), '^\d+$')
UNION
SELECT TO_NUMBER(TRIM(code)), TRIM(name), TRIM(gender),
    CASE WHEN birth_date IS NOT NULL AND TRIM(birth_date) != ''
         THEN CAST(TO_TIMESTAMP(TRIM(birth_date), 'DD-MON-RR HH.MI.SS.FF9 AM') AS DATE)
         ELSE NULL END
FROM TEMP_TECH_OFFICIALS
WHERE code IS NOT NULL AND REGEXP_LIKE(TRIM(code), '^\d+$');
COMMIT;
SELECT 'Person' AS tbl, COUNT(*) AS cnt FROM Person;


-- 8. Athlete
-- height/weight: CASE WHEN guards against non-numeric values (dot, empty string).
-- TO_NUMBER with NLS_NUMERIC_CHARACTERS forces dot as decimal separator
-- regardless of session NLS settings, which vary by OS locale.
INSERT INTO Athlete (code, name_short, height, weight, birth_place, country_code)
SELECT
    TO_NUMBER(TRIM(code)),
    TRIM(name_short),
    CASE WHEN TRIM(height) IS NOT NULL AND TRIM(height) != ''
              AND TRIM(height) != '.' AND REGEXP_LIKE(TRIM(height), '^[0-9]')
         THEN TO_NUMBER(REPLACE(TRIM(height), ',', '.'),
                        '999.99', 'NLS_NUMERIC_CHARACTERS=''.,''')
         ELSE NULL END,
    CASE WHEN TRIM(weight) IS NOT NULL AND TRIM(weight) != ''
              AND TRIM(weight) != '.' AND REGEXP_LIKE(TRIM(weight), '^[0-9]')
         THEN TO_NUMBER(REPLACE(TRIM(weight), ',', '.'),
                        '999.99', 'NLS_NUMERIC_CHARACTERS=''.,''')
         ELSE NULL END,
    TRIM(birth_place),
    TRIM(country_code)
FROM TEMP_ATHLETES
WHERE code IS NOT NULL
  AND REGEXP_LIKE(TRIM(code), '^\d+$')
  AND country_code IS NOT NULL
  AND EXISTS (SELECT 1 FROM Person  p WHERE p.code         = TO_NUMBER(TRIM(code)))
  AND EXISTS (SELECT 1 FROM Country c WHERE c.country_code = TRIM(country_code));
COMMIT;
SELECT 'Athlete' AS tbl, COUNT(*) AS cnt FROM Athlete;


-- 9. Coach
-- function_col in TEMP table because FUNCTION is a reserved Oracle keyword.
INSERT INTO Coach (code, function, country_code)
SELECT TO_NUMBER(TRIM(code)), TRIM(function_col), TRIM(country_code)
FROM TEMP_COACHES
WHERE code IS NOT NULL
  AND REGEXP_LIKE(TRIM(code), '^\d+$')
  AND country_code IS NOT NULL
  AND EXISTS (SELECT 1 FROM Person  p WHERE p.code         = TO_NUMBER(TRIM(code)))
  AND EXISTS (SELECT 1 FROM Country c WHERE c.country_code = TRIM(country_code));
COMMIT;
SELECT 'Coach' AS tbl, COUNT(*) AS cnt FROM Coach;


-- 10. TechnicalOfficial
INSERT INTO TechnicalOfficial (code, function, organisation_code)
SELECT TO_NUMBER(TRIM(code)), TRIM(function_col), TRIM(organisation_code)
FROM TEMP_TECH_OFFICIALS
WHERE code IS NOT NULL
  AND REGEXP_LIKE(TRIM(code), '^\d+$')
  AND organisation_code IS NOT NULL
  AND EXISTS (SELECT 1 FROM Person       p WHERE p.code              = TO_NUMBER(TRIM(code)))
  AND EXISTS (SELECT 1 FROM Organisation o WHERE o.organisation_code = TRIM(organisation_code));
COMMIT;
SELECT 'TechnicalOfficial' AS tbl, COUNT(*) AS cnt FROM TechnicalOfficial;


-- 11. Team
INSERT INTO Team (team_code, team_name, team_gender, country_code)
SELECT TRIM(code), TRIM(team), TRIM(team_gender), TRIM(country_code)
FROM TEMP_TEAMS
WHERE code IS NOT NULL
  AND country_code IS NOT NULL
  AND EXISTS (SELECT 1 FROM Country c WHERE c.country_code = TRIM(country_code));
COMMIT;
SELECT 'Team' AS tbl, COUNT(*) AS cnt FROM Team;


-- 12. Sponsor
INSERT INTO Sponsor (sponsor_id, company_name, industry, sponsorship_budget, country_code)
SELECT
    TO_NUMBER(TRIM(sponsor_id)),
    TRIM(company_name),
    TRIM(industry),
    TO_NUMBER(REPLACE(TRIM(sponsorship_budget), ',', '.'),
              '999999999999999.99', 'NLS_NUMERIC_CHARACTERS=''.,'''),
    TRIM(country_code)
FROM TEMP_SPONSORS
WHERE sponsor_id IS NOT NULL
  AND EXISTS (SELECT 1 FROM Country c WHERE c.country_code = TRIM(country_code));
COMMIT;
SELECT 'Sponsor' AS tbl, COUNT(*) AS cnt FROM Sponsor;


-- 13. Schedule
-- start_date/end_date format in CSV: '2024-07-24T15:00:00+02:00'
-- TZH:TZM in format mask handles the +02:00 timezone offset.
-- venue_code in schedules.csv differs from venue_tag in venues.csv.
-- DECODE() provides 40-entry manual mapping between the two systems.
-- Several codes map to the same venue (LC1-LC4 -> la-concorde, SP1/SP4/SP6 -> south-paris-arena).
INSERT INTO Schedule (schedule_id, start_date, end_date, day, status, phase, venue_tag, event_tag)
SELECT
    schedule_seq.NEXTVAL,
    TO_TIMESTAMP_TZ(TRIM(start_date), 'YYYY-MM-DD"T"HH24:MI:SSTZH:TZM'),
    TO_TIMESTAMP_TZ(TRIM(end_date),   'YYYY-MM-DD"T"HH24:MI:SSTZH:TZM'),
    TO_DATE(SUBSTR(TRIM(day), 1, 10), 'YYYY-MM-DD'),
    TRIM(status),
    TRIM(phase),
    DECODE(TRIM(venue_code),
        'ALX', 'pont-alexandre-iii',           'AQC', 'aquatics-centre',
        'BCY', 'bercy-arena',                  'BOR', 'bordeaux-stadium',
        'CDM', 'champ-de-mars-arena',          'CPL', 'porte-de-la-chapelle-arena',
        'CTX', 'chateauroux-shooting-centre',  'DEF', 'paris-la-defense-arena',
        'EIF', 'eiffel-tower-stadium',         'ELA', 'elancourt-hill',
        'GRP', 'grand-palais',                 'INV', 'invalides',
        'LBO', 'le-bourget-climbing-venue',    'LC1', 'la-concorde',
        'LC2', 'la-concorde',                  'LC3', 'la-concorde',
        'LC4', 'la-concorde',                  'LGN', 'le-golf-national',
        'LIL', 'pierre-mauroy-stadium',        'LYO', 'lyon-stadium',
        'MAM', 'marseille-marina',             'MRS', 'marseille-stadium',
        'NAN', 'la-beaujoire-stadium',         'NIC', 'nice-stadium',
        'NPA', 'north-paris-arena',            'PDP', 'parc-des-princes',
        'RGA', 'roland-garros-stadium',        'SP1', 'south-paris-arena',
        'SP4', 'south-paris-arena',            'SP6', 'south-paris-arena',
        'STA', 'stade-de-france',              'STE', 'geoffroy-guichard-stadium',
        'TAH', 'teahupo-o-tahiti',             'TRO', 'trocadero',
        'VE1', 'saint-quentin-en-yvelines-velodrome',
        'VE2', 'saint-quentin-en-yvelines-bmx-stadium',
        'VER', 'chateau-de-versailles',
        'VN1', 'vaires-sur-marne-nautical-stadium',
        'VN2', 'vaires-sur-marne-nautical-stadium',
        'YDM', 'yves-du-manoir-stadium',
        NULL),
    TRIM(discipline_code) || '-' ||
        REGEXP_REPLACE(
            REPLACE(REPLACE(TRIM(event), '+', 'plus'), '-', 'minus'),
        '[^a-zA-Z0-9]', '-')
FROM TEMP_SCHEDULES
WHERE start_date IS NOT NULL
  AND EXISTS (
      SELECT 1 FROM Event e
      WHERE e.event_tag = TRIM(discipline_code) || '-' ||
          REGEXP_REPLACE(
              REPLACE(REPLACE(TRIM(event), '+', 'plus'), '-', 'minus'),
          '[^a-zA-Z0-9]', '-')
  );
COMMIT;
SELECT 'Schedule' AS tbl, COUNT(*) AS cnt FROM Schedule;


-- 14. AthleteMemberOfTeam
-- athletes_codes stores Python list strings e.g. "['1913366', '1913367']".
-- PL/SQL block parses each list using REGEXP_SUBSTR with occurrence counter.
BEGIN
    FOR team_row IN (
        SELECT TRIM(code) AS team_code, TRIM(athletes_codes) AS athletes_codes
        FROM TEMP_TEAMS
        WHERE athletes_codes IS NOT NULL
          AND LENGTH(TRIM(athletes_codes)) > 2
          AND REGEXP_LIKE(TRIM(athletes_codes), '\d')
    ) LOOP
        FOR i IN 1..REGEXP_COUNT(team_row.athletes_codes, '\d+') LOOP
            DECLARE
                v_code VARCHAR2(20);
                v_tc   NUMBER; v_ac NUMBER;
            BEGIN
                v_code := REGEXP_SUBSTR(team_row.athletes_codes, '\d+', 1, i);
                IF v_code IS NOT NULL THEN
                    SELECT COUNT(*) INTO v_tc FROM Team    WHERE team_code = team_row.team_code;
                    SELECT COUNT(*) INTO v_ac FROM Athlete WHERE code      = TO_NUMBER(v_code);
                    IF v_tc > 0 AND v_ac > 0 THEN
                        INSERT INTO AthleteMemberOfTeam (team_code, athlete_code)
                        VALUES (team_row.team_code, TO_NUMBER(v_code));
                    END IF;
                END IF;
            EXCEPTION WHEN DUP_VAL_ON_INDEX THEN NULL; WHEN OTHERS THEN NULL;
            END;
        END LOOP;
    END LOOP;
    COMMIT;
END;
/
SELECT 'AthleteMemberOfTeam' AS tbl, COUNT(*) AS cnt FROM AthleteMemberOfTeam;


-- 15. CoachTrainsTeam
-- Same list-parsing approach as AthleteMemberOfTeam.
BEGIN
    FOR team_row IN (
        SELECT TRIM(code) AS team_code, TRIM(coaches_codes) AS coaches_codes
        FROM TEMP_TEAMS
        WHERE coaches_codes IS NOT NULL
          AND LENGTH(TRIM(coaches_codes)) > 2
          AND REGEXP_LIKE(TRIM(coaches_codes), '\d')
    ) LOOP
        FOR i IN 1..REGEXP_COUNT(team_row.coaches_codes, '\d+') LOOP
            DECLARE
                v_code VARCHAR2(20);
                v_tc   NUMBER; v_cc NUMBER;
            BEGIN
                v_code := REGEXP_SUBSTR(team_row.coaches_codes, '\d+', 1, i);
                IF v_code IS NOT NULL THEN
                    SELECT COUNT(*) INTO v_tc FROM Team  WHERE team_code = team_row.team_code;
                    SELECT COUNT(*) INTO v_cc FROM Coach WHERE code      = TO_NUMBER(v_code);
                    IF v_tc > 0 AND v_cc > 0 THEN
                        INSERT INTO CoachTrainsTeam (team_code, coach_code)
                        VALUES (team_row.team_code, TO_NUMBER(v_code));
                    END IF;
                END IF;
            EXCEPTION WHEN DUP_VAL_ON_INDEX THEN NULL; WHEN OTHERS THEN NULL;
            END;
        END LOOP;
    END LOOP;
    COMMIT;
END;
/
SELECT 'CoachTrainsTeam' AS tbl, COUNT(*) AS cnt FROM CoachTrainsTeam;


-- 16. CoachWorksInSport
-- disciplines in coaches.csv is plain text sport name — matched to Sport via JOIN.
INSERT INTO CoachWorksInSport (sport_code, coach_code)
SELECT DISTINCT s.sport_code, TO_NUMBER(TRIM(tc.code))
FROM TEMP_COACHES tc
JOIN Sport s ON UPPER(TRIM(s.sport_name)) = UPPER(TRIM(tc.disciplines))
WHERE tc.code IS NOT NULL
  AND REGEXP_LIKE(TRIM(tc.code), '^\d+$')
  AND tc.disciplines IS NOT NULL
  AND EXISTS (SELECT 1 FROM Coach c WHERE c.code = TO_NUMBER(TRIM(tc.code)));
COMMIT;
SELECT 'CoachWorksInSport' AS tbl, COUNT(*) AS cnt FROM CoachWorksInSport;


-- 17. TechOfficialOfficiatesInSport
-- disciplines in technical_officials.csv stores Python list e.g. "['Hockey']".
-- REGEXP_REPLACE strips [ ] ' characters, then INSTR checks sport name containment.
-- Handles officials assigned to multiple sports in one list string.
INSERT INTO TechOfficialOfficiatesInSport (tech_code, sport_code)
SELECT DISTINCT TO_NUMBER(TRIM(tt.code)), s.sport_code
FROM TEMP_TECH_OFFICIALS tt
JOIN Sport s ON INSTR(
    UPPER(REGEXP_REPLACE(TRIM(tt.disciplines), '[\[\]'']', '')),
    UPPER(TRIM(s.sport_name))
) > 0
WHERE tt.code IS NOT NULL
  AND REGEXP_LIKE(TRIM(tt.code), '^\d+$')
  AND tt.disciplines IS NOT NULL
  AND EXISTS (SELECT 1 FROM TechnicalOfficial t WHERE t.code = TO_NUMBER(TRIM(tt.code)));
COMMIT;
SELECT 'TechOfficialOfficiatesInSport' AS tbl, COUNT(*) AS cnt FROM TechOfficialOfficiatesInSport;


-- 18. AthleteWinsMedal
-- medal_code in CSV is decimal (1.0, 2.0) — ROUND converts to integer.
-- medal_date converted using FF9 format (9-digit nanoseconds from Data Load).
-- discipline (sport name text) joined to Sport to get sport_code for event_tag.
INSERT INTO AthleteWinsMedal (medal_code, event_tag, athlete_code, medal_date)
SELECT DISTINCT
    ROUND(TO_NUMBER(REPLACE(TRIM(tm.medal_code), ',', '.'),
                   '9.9', 'NLS_NUMERIC_CHARACTERS=''.,''')),
    s.sport_code || '-' ||
        REGEXP_REPLACE(
            REPLACE(REPLACE(TRIM(tm.event), '+', 'plus'), '-', 'minus'),
        '[^a-zA-Z0-9]', '-'),
    TO_NUMBER(TRIM(tm.code_athlete)),
    CASE WHEN REGEXP_LIKE(TRIM(tm.medal_date), '^\d{4}-\d{2}-\d{2}$')
         THEN TO_DATE(TRIM(tm.medal_date), 'YYYY-MM-DD')
         ELSE CAST(TO_TIMESTAMP(TRIM(tm.medal_date), 'DD-MON-RR HH.MI.SS.FF9 AM') AS DATE)
         END
FROM TEMP_MEDALLISTS tm
JOIN Sport s ON UPPER(TRIM(s.sport_name)) = UPPER(TRIM(tm.discipline))
WHERE tm.code_athlete IS NOT NULL
  AND REGEXP_LIKE(TRIM(tm.code_athlete), '^\d+$')
  AND tm.medal_code IS NOT NULL
  AND REGEXP_LIKE(TRIM(tm.medal_code), '^[0-9]')
  AND ROUND(TO_NUMBER(REPLACE(TRIM(tm.medal_code), ',', '.'),
                      '9.9', 'NLS_NUMERIC_CHARACTERS=''.,''')) IN (1, 2, 3)
  AND EXISTS (SELECT 1 FROM Athlete a WHERE a.code = TO_NUMBER(TRIM(tm.code_athlete)))
  AND EXISTS (
      SELECT 1 FROM Event e
      WHERE e.event_tag = s.sport_code || '-' ||
          REGEXP_REPLACE(
              REPLACE(REPLACE(TRIM(tm.event), '+', 'plus'), '-', 'minus'),
          '[^a-zA-Z0-9]', '-')
  );
COMMIT;
SELECT 'AthleteWinsMedal' AS tbl, COUNT(*) AS cnt FROM AthleteWinsMedal;


-- 19. AthleteCompetesInEvent
-- Populated from medallists.csv only (no full participation list in source data).
-- medal_date used as start_date — only date available linking athlete to event.
INSERT INTO AthleteCompetesInEvent (athlete_code, event_tag, start_date)
SELECT DISTINCT
    TO_NUMBER(TRIM(tm.code_athlete)),
    s.sport_code || '-' ||
        REGEXP_REPLACE(
            REPLACE(REPLACE(TRIM(tm.event), '+', 'plus'), '-', 'minus'),
        '[^a-zA-Z0-9]', '-'),
    CASE WHEN REGEXP_LIKE(TRIM(tm.medal_date), '^\d{4}-\d{2}-\d{2}$')
         THEN TO_DATE(TRIM(tm.medal_date), 'YYYY-MM-DD')
         ELSE CAST(TO_TIMESTAMP(TRIM(tm.medal_date), 'DD-MON-RR HH.MI.SS.FF9 AM') AS DATE)
         END
FROM TEMP_MEDALLISTS tm
JOIN Sport s ON UPPER(TRIM(s.sport_name)) = UPPER(TRIM(tm.discipline))
WHERE tm.code_athlete IS NOT NULL
  AND REGEXP_LIKE(TRIM(tm.code_athlete), '^\d+$')
  AND EXISTS (SELECT 1 FROM Athlete a WHERE a.code = TO_NUMBER(TRIM(tm.code_athlete)))
  AND EXISTS (
      SELECT 1 FROM Event e
      WHERE e.event_tag = s.sport_code || '-' ||
          REGEXP_REPLACE(
              REPLACE(REPLACE(TRIM(tm.event), '+', 'plus'), '-', 'minus'),
          '[^a-zA-Z0-9]', '-')
  );
COMMIT;
SELECT 'AthleteCompetesInEvent' AS tbl, COUNT(*) AS cnt FROM AthleteCompetesInEvent;


-- 20. SponsorSponsorsCountry
-- country_code in sponsors.csv serves dual role: headquarters country and supported country.
INSERT INTO SponsorSponsorsCountry (sponsor_id, country_code)
SELECT TO_NUMBER(TRIM(sponsor_id)), TRIM(country_code)
FROM TEMP_SPONSORS
WHERE sponsor_id IS NOT NULL
  AND country_code IS NOT NULL
  AND EXISTS (SELECT 1 FROM Sponsor  s WHERE s.sponsor_id   = TO_NUMBER(TRIM(TEMP_SPONSORS.sponsor_id)))
  AND EXISTS (SELECT 1 FROM Country  c WHERE c.country_code = TRIM(TEMP_SPONSORS.country_code));
COMMIT;
SELECT 'SponsorSponsorsCountry' AS tbl, COUNT(*) AS cnt FROM SponsorSponsorsCountry;


-- Final verification
SELECT tbl, cnt,
    CASE
        WHEN tbl = 'Country'                       AND cnt >= 220   THEN 'OK'
        WHEN tbl = 'Organisation'                  AND cnt >= 100   THEN 'OK'
        WHEN tbl = 'Sport'                         AND cnt >= 40    THEN 'OK'
        WHEN tbl = 'Medal'                         AND cnt = 3      THEN 'OK'
        WHEN tbl = 'Venue'                         AND cnt >= 30    THEN 'OK'
        WHEN tbl = 'Person'                        AND cnt >= 12000 THEN 'OK'
        WHEN tbl = 'Athlete'                       AND cnt >= 10000 THEN 'OK'
        WHEN tbl = 'Coach'                         AND cnt >= 900   THEN 'OK'
        WHEN tbl = 'TechnicalOfficial'             AND cnt >= 900   THEN 'OK'
        WHEN tbl = 'Team'                          AND cnt >= 1600  THEN 'OK'
        WHEN tbl = 'Sponsor'                       AND cnt >= 140   THEN 'OK'
        WHEN tbl = 'Event'                         AND cnt >= 320   THEN 'OK'
        WHEN tbl = 'Schedule'                      AND cnt >= 3000  THEN 'OK'
        WHEN tbl = 'AthleteMemberOfTeam'           AND cnt >= 4000  THEN 'OK'
        WHEN tbl = 'CoachTrainsTeam'               AND cnt >= 400   THEN 'OK'
        WHEN tbl = 'CoachWorksInSport'             AND cnt >= 800   THEN 'OK'
        WHEN tbl = 'TechOfficialOfficiatesInSport' AND cnt >= 800   THEN 'OK'
        WHEN tbl = 'AthleteWinsMedal'              AND cnt >= 1500  THEN 'OK'
        WHEN tbl = 'AthleteCompetesInEvent'        AND cnt >= 1500  THEN 'OK'
        WHEN tbl = 'SponsorSponsorsCountry'        AND cnt >= 140   THEN 'OK'
        ELSE '*** CHECK ***'
    END AS status
FROM (
    SELECT 'Country'                        AS tbl, COUNT(*) AS cnt FROM Country                       UNION ALL
    SELECT 'Organisation',                           COUNT(*)        FROM Organisation                  UNION ALL
    SELECT 'Sport',                                  COUNT(*)        FROM Sport                         UNION ALL
    SELECT 'Medal',                                  COUNT(*)        FROM Medal                         UNION ALL
    SELECT 'Venue',                                  COUNT(*)        FROM Venue                         UNION ALL
    SELECT 'Person',                                 COUNT(*)        FROM Person                        UNION ALL
    SELECT 'Athlete',                                COUNT(*)        FROM Athlete                       UNION ALL
    SELECT 'Coach',                                  COUNT(*)        FROM Coach                         UNION ALL
    SELECT 'TechnicalOfficial',                      COUNT(*)        FROM TechnicalOfficial             UNION ALL
    SELECT 'Team',                                   COUNT(*)        FROM Team                          UNION ALL
    SELECT 'Sponsor',                                COUNT(*)        FROM Sponsor                       UNION ALL
    SELECT 'Event',                                  COUNT(*)        FROM Event                         UNION ALL
    SELECT 'Schedule',                               COUNT(*)        FROM Schedule                      UNION ALL
    SELECT 'AthleteMemberOfTeam',                    COUNT(*)        FROM AthleteMemberOfTeam           UNION ALL
    SELECT 'CoachTrainsTeam',                        COUNT(*)        FROM CoachTrainsTeam               UNION ALL
    SELECT 'CoachWorksInSport',                      COUNT(*)        FROM CoachWorksInSport             UNION ALL
    SELECT 'TechOfficialOfficiatesInSport',          COUNT(*)        FROM TechOfficialOfficiatesInSport UNION ALL
    SELECT 'AthleteWinsMedal',                       COUNT(*)        FROM AthleteWinsMedal              UNION ALL
    SELECT 'AthleteCompetesInEvent',                 COUNT(*)        FROM AthleteCompetesInEvent        UNION ALL
    SELECT 'SponsorSponsorsCountry',                 COUNT(*)        FROM SponsorSponsorsCountry
)
ORDER BY tbl;
