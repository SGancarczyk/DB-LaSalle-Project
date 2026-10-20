# Paris 2024 Olympic Games Database
## Author: Stanislaw Gancarczyk | Databases 2025-2026 | La Salle URL

---

## Scripts

| File | Purpose |
|---|---|
| `G_physicalmodel.sql` | Creates all 20 tables and the schedule_seq sequence |
| `G_import.sql` | Creates TEMP tables, then populates physical tables via INSERT-SELECT |
| `G_queries.sql` | 32 queries, bonus RANK() query, and 3 triggers |

The import script requires a manual step in the middle — loading CSV files via the
Data Load wizard. The file contains a `-- STOP HERE` marker indicating exactly where
to pause. This is unavoidable: Data Load is a GUI tool and cannot be called from SQL.

---

## How to Run

**Step 1 — Physical model**
Open `G_physicalmodel.sql` in SQL Developer and press F5.
The script drops and recreates all objects automatically. Safe to run multiple times.

**Step 2 — Create TEMP tables**
Open `G_import.sql`. Select all lines from the top down to and including the
`-- STOP HERE` comment. Press F9 (Run Selected).
This creates 11 empty TEMP tables ready to receive CSV data.

**Step 3 — Load CSV files**
Right-click each TEMP table in the Navigator panel, select Import Data,
and load the corresponding CSV file:

| CSV file | TEMP table |
|---|---|
| nocs.csv | TEMP_NOCS |
| venues.csv | TEMP_VENUES |
| events.csv | TEMP_EVENTS |
| medals.csv | TEMP_MEDALS |
| athletes.csv | TEMP_ATHLETES |
| coaches.csv | TEMP_COACHES |
| technical_officials.csv | TEMP_TECH_OFFICIALS |
| teams.csv | TEMP_TEAMS |
| schedules.csv | TEMP_SCHEDULES |
| medallists.csv | TEMP_MEDALLISTS |
| sponsors.csv | TEMP_SPONSORS |

Note: athletes.csv and coaches.csv contain columns named `current` and `function`,
which are reserved words in Oracle. During Data Load column mapping, assign these
manually to `current_flag` and `function_col` respectively.

**Step 4 — Populate physical tables**
In `G_import.sql`, select all lines from after the `-- STOP HERE` marker to the end
of the file. Press F9 (Run Selected).
All data moves from TEMP tables into the physical model. Safe to run multiple times.
The final output lists all 20 tables with row counts and OK/CHECK status.

**Step 5 — Queries and triggers**
Open `G_queries.sql` and press F5.
Runs all 32 queries, the bonus RANK() query, and creates and tests all 3 triggers.

---

## Expected Row Counts After Import

| Table | Rows |
|---|---|
| Country | 224 |
| Organisation | 107 |
| Sport | 45 |
| Medal | 3 |
| Venue | 35 |
| Person | 13,108 |
| Athlete | 11,113 |
| Coach | 974 |
| TechnicalOfficial | 1,021 |
| Team | 1,698 |
| Sponsor | 150 |
| Event | 329 |
| Schedule | 3,885 |
| AthleteMemberOfTeam | 6,990 |
| CoachTrainsTeam | 513 |
| CoachWorksInSport | 974 |
| TechOfficialOfficiatesInSport | 1,238 |
| AthleteWinsMedal | 2,314 |
| AthleteCompetesInEvent | 2,315 |
| SponsorSponsorsCountry | 150 |
