-- G_physicalmodel.sql
-- Paris 2024 Olympic Games — Physical Model
-- Author: Stanislaw Gancarczyk
-- Databases 2025-2026, La Salle - Universitat Ramon Llull
--
-- Idempotent: drops all objects first, then recreates them.
-- Run multiple times without errors.


-- Drop junction tables first (children before parents)
DROP TABLE SponsorSponsorsCountry        CASCADE CONSTRAINTS PURGE;
DROP TABLE TechOfficialOfficiatesInSport CASCADE CONSTRAINTS PURGE;
DROP TABLE CoachWorksInSport             CASCADE CONSTRAINTS PURGE;
DROP TABLE CoachTrainsTeam               CASCADE CONSTRAINTS PURGE;
DROP TABLE AthleteMemberOfTeam           CASCADE CONSTRAINTS PURGE;
DROP TABLE AthleteWinsMedal              CASCADE CONSTRAINTS PURGE;
DROP TABLE AthleteCompetesInEvent        CASCADE CONSTRAINTS PURGE;

-- Drop entity tables
DROP TABLE Schedule          CASCADE CONSTRAINTS PURGE;
DROP TABLE TechnicalOfficial CASCADE CONSTRAINTS PURGE;
DROP TABLE Coach             CASCADE CONSTRAINTS PURGE;
DROP TABLE Athlete           CASCADE CONSTRAINTS PURGE;
DROP TABLE Person            CASCADE CONSTRAINTS PURGE;
DROP TABLE Team              CASCADE CONSTRAINTS PURGE;
DROP TABLE Sponsor           CASCADE CONSTRAINTS PURGE;
DROP TABLE Event             CASCADE CONSTRAINTS PURGE;
DROP TABLE Venue             CASCADE CONSTRAINTS PURGE;
DROP TABLE Medal             CASCADE CONSTRAINTS PURGE;
DROP TABLE Organisation      CASCADE CONSTRAINTS PURGE;
DROP TABLE Sport             CASCADE CONSTRAINTS PURGE;
DROP TABLE Country           CASCADE CONSTRAINTS PURGE;

DROP SEQUENCE schedule_seq;


-- Country
-- Source: nocs.csv. Stores NOC codes, not geographic countries.
-- Includes AIN (neutral athletes) and historical NOCs.
CREATE TABLE Country (
    country_code    VARCHAR2(3)     NOT NULL,   -- 3-letter NOC code
    country         VARCHAR2(50),
    country_long    VARCHAR2(100),
    tag             VARCHAR2(50),
    note            VARCHAR2(3),                -- P / H / NP
    CONSTRAINT pk_country PRIMARY KEY (country_code)
);


-- Organisation
-- Source: technical_officials.csv.
-- Separate from Country because officials can be appointed by international
-- federations (FIG, FIBA, UCI) whose codes are not in nocs.csv.
CREATE TABLE Organisation (
    organisation_code   VARCHAR2(10)    NOT NULL,
    organisation        VARCHAR2(60),
    organisation_long   VARCHAR2(100),
    CONSTRAINT pk_organisation PRIMARY KEY (organisation_code)
);


-- Sport
-- Source: events.csv (sport, sport_code, sport_url columns).
CREATE TABLE Sport (
    sport_code  VARCHAR2(3)     NOT NULL,
    sport_name  VARCHAR2(60),
    sport_url   VARCHAR2(150),
    CONSTRAINT pk_sport PRIMARY KEY (sport_code)
);


-- Medal
-- Only 3 rows: Gold=1, Silver=2, Bronze=3.
-- medal_description not in source CSV, inserted manually during import.
CREATE TABLE Medal (
    medal_code          NUMBER(1)       NOT NULL,
    medal_type          VARCHAR2(20),
    medal_description   VARCHAR2(200),
    CONSTRAINT pk_medal PRIMARY KEY (medal_code)
);


-- Venue
-- Source: venues.csv.
-- venue_tag is the URL slug (e.g. 'aquatics-centre').
-- schedules.csv uses short codes mapped via DECODE() in import script.
CREATE TABLE Venue (
    venue_tag   VARCHAR2(60)    NOT NULL,
    venue_name  VARCHAR2(100),
    date_start  DATE,
    date_end    DATE,
    CONSTRAINT pk_venue PRIMARY KEY (venue_tag)
);


-- Person — parent table in the generalisation hierarchy.
-- Source: athletes.csv + coaches.csv + technical_officials.csv (UNION).
CREATE TABLE Person (
    code        NUMBER(10)      NOT NULL,   -- max observed: 9,460,001
    name        VARCHAR2(100),
    gender      VARCHAR2(10),
    birth_date  DATE,
    CONSTRAINT pk_person PRIMARY KEY (code)
);


-- Athlete — specialisation of Person.
CREATE TABLE Athlete (
    code         NUMBER(10)  NOT NULL,
    name_short   VARCHAR2(30),
    height       NUMBER(5,2),        -- cm, nullable
    weight       NUMBER(5,2),        -- kg, nullable
    birth_place  VARCHAR2(100),
    country_code VARCHAR2(3)  NOT NULL,
    CONSTRAINT pk_athlete         PRIMARY KEY (code),
    CONSTRAINT fk_athlete_person  FOREIGN KEY (code)         REFERENCES Person  (code),
    CONSTRAINT fk_athlete_country FOREIGN KEY (country_code) REFERENCES Country (country_code)
);


-- Coach — specialisation of Person.
CREATE TABLE Coach (
    code         NUMBER(10)  NOT NULL,
    function     VARCHAR2(30),
    country_code VARCHAR2(3) NOT NULL,
    CONSTRAINT pk_coach         PRIMARY KEY (code),
    CONSTRAINT fk_coach_person  FOREIGN KEY (code)         REFERENCES Person  (code),
    CONSTRAINT fk_coach_country FOREIGN KEY (country_code) REFERENCES Country (country_code)
);


-- TechnicalOfficial — specialisation of Person.
-- FK to Organisation, not Country, because many officials are appointed
-- by international federations rather than national committees.
CREATE TABLE TechnicalOfficial (
    code                NUMBER(10)  NOT NULL,
    function            VARCHAR2(40),
    organisation_code   VARCHAR2(10) NOT NULL,
    CONSTRAINT pk_techofficial   PRIMARY KEY (code),
    CONSTRAINT fk_techoff_person FOREIGN KEY (code)              REFERENCES Person       (code),
    CONSTRAINT fk_techoff_org    FOREIGN KEY (organisation_code) REFERENCES Organisation (organisation_code)
);


-- Team
-- Source: teams.csv. team_code encodes sport, gender, country.
CREATE TABLE Team (
    team_code    VARCHAR2(30)    NOT NULL,
    team_name    VARCHAR2(100),
    team_gender  VARCHAR2(5),
    country_code VARCHAR2(3)    NOT NULL,
    CONSTRAINT pk_team         PRIMARY KEY (team_code),
    CONSTRAINT fk_team_country FOREIGN KEY (country_code) REFERENCES Country (country_code)
);


-- Sponsor
-- Source: sponsors.csv (custom Mockaroo-generated file).
-- country_code = headquarters country (1:N).
-- N:M support relationships stored in SponsorSponsorsCountry.
CREATE TABLE Sponsor (
    sponsor_id          NUMBER(10)      NOT NULL,
    company_name        VARCHAR2(100),
    industry            VARCHAR2(50),
    sponsorship_budget  NUMBER(15,2),
    country_code        VARCHAR2(3),
    CONSTRAINT pk_sponsor         PRIMARY KEY (sponsor_id),
    CONSTRAINT fk_sponsor_country FOREIGN KEY (country_code) REFERENCES Country (country_code)
);


-- Event
-- Source: events.csv.
-- event_tag is synthetic: sport_code + '-' + cleaned event name.
-- Same formula used consistently across all inserts referencing event_tag.
CREATE TABLE Event (
    event_tag   VARCHAR2(80)    NOT NULL,
    event_name  VARCHAR2(80),
    gender      VARCHAR2(10),
    sport_code  VARCHAR2(3)     NOT NULL,
    CONSTRAINT pk_event       PRIMARY KEY (event_tag),
    CONSTRAINT fk_event_sport FOREIGN KEY (sport_code) REFERENCES Sport (sport_code)
);


-- Schedule
-- Source: schedules.csv.
-- Surrogate key used — no natural unique identifier in the source CSV.
-- TIMESTAMP WITH TIME ZONE preserves the +02:00 offset from the source data.
CREATE SEQUENCE schedule_seq START WITH 1 INCREMENT BY 1 NOCACHE NOCYCLE;

CREATE TABLE Schedule (
    schedule_id NUMBER(10)              NOT NULL,
    start_date  TIMESTAMP WITH TIME ZONE,
    end_date    TIMESTAMP WITH TIME ZONE,
    day         DATE,
    status      VARCHAR2(15),
    phase       VARCHAR2(100),
    venue_tag   VARCHAR2(60),
    event_tag   VARCHAR2(80),
    CONSTRAINT pk_schedule       PRIMARY KEY (schedule_id),
    CONSTRAINT fk_schedule_venue FOREIGN KEY (venue_tag)  REFERENCES Venue (venue_tag),
    CONSTRAINT fk_schedule_event FOREIGN KEY (event_tag)  REFERENCES Event (event_tag)
);


-- Junction tables

CREATE TABLE AthleteCompetesInEvent (
    athlete_code    NUMBER(10)   NOT NULL,
    event_tag       VARCHAR2(80) NOT NULL,
    start_date      DATE,
    CONSTRAINT pk_ace         PRIMARY KEY (athlete_code, event_tag),
    CONSTRAINT fk_ace_athlete FOREIGN KEY (athlete_code) REFERENCES Athlete (code),
    CONSTRAINT fk_ace_event   FOREIGN KEY (event_tag)    REFERENCES Event   (event_tag)
);

CREATE TABLE AthleteWinsMedal (
    medal_code      NUMBER(1)    NOT NULL,
    event_tag       VARCHAR2(80) NOT NULL,
    athlete_code    NUMBER(10)   NOT NULL,
    medal_date      DATE,
    CONSTRAINT pk_awm         PRIMARY KEY (medal_code, event_tag, athlete_code),
    CONSTRAINT fk_awm_medal   FOREIGN KEY (medal_code)   REFERENCES Medal   (medal_code),
    CONSTRAINT fk_awm_event   FOREIGN KEY (event_tag)    REFERENCES Event   (event_tag),
    CONSTRAINT fk_awm_athlete FOREIGN KEY (athlete_code) REFERENCES Athlete (code)
);

CREATE TABLE AthleteMemberOfTeam (
    team_code       VARCHAR2(30) NOT NULL,
    athlete_code    NUMBER(10)   NOT NULL,
    CONSTRAINT pk_amot         PRIMARY KEY (team_code, athlete_code),
    CONSTRAINT fk_amot_team    FOREIGN KEY (team_code)    REFERENCES Team    (team_code),
    CONSTRAINT fk_amot_athlete FOREIGN KEY (athlete_code) REFERENCES Athlete (code)
);

CREATE TABLE CoachTrainsTeam (
    team_code   VARCHAR2(30) NOT NULL,
    coach_code  NUMBER(10)   NOT NULL,
    CONSTRAINT pk_ctt       PRIMARY KEY (team_code, coach_code),
    CONSTRAINT fk_ctt_team  FOREIGN KEY (team_code)  REFERENCES Team  (team_code),
    CONSTRAINT fk_ctt_coach FOREIGN KEY (coach_code) REFERENCES Coach (code)
);

CREATE TABLE CoachWorksInSport (
    sport_code  VARCHAR2(3)  NOT NULL,
    coach_code  NUMBER(10)   NOT NULL,
    CONSTRAINT pk_cwis       PRIMARY KEY (sport_code, coach_code),
    CONSTRAINT fk_cwis_sport FOREIGN KEY (sport_code) REFERENCES Sport (sport_code),
    CONSTRAINT fk_cwis_coach FOREIGN KEY (coach_code) REFERENCES Coach (code)
);

CREATE TABLE TechOfficialOfficiatesInSport (
    tech_code   NUMBER(10)  NOT NULL,
    sport_code  VARCHAR2(3) NOT NULL,
    CONSTRAINT pk_toois       PRIMARY KEY (tech_code, sport_code),
    CONSTRAINT fk_toois_tech  FOREIGN KEY (tech_code)  REFERENCES TechnicalOfficial (code),
    CONSTRAINT fk_toois_sport FOREIGN KEY (sport_code) REFERENCES Sport             (sport_code)
);

CREATE TABLE SponsorSponsorsCountry (
    sponsor_id      NUMBER(10)  NOT NULL,
    country_code    VARCHAR2(3) NOT NULL,
    CONSTRAINT pk_ssc         PRIMARY KEY (sponsor_id, country_code),
    CONSTRAINT fk_ssc_sponsor FOREIGN KEY (sponsor_id)   REFERENCES Sponsor (sponsor_id),
    CONSTRAINT fk_ssc_country FOREIGN KEY (country_code) REFERENCES Country (country_code)
);
