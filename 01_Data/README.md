This folder contains the original and cleaned datasets.


 Part 1: Cleaning the raw data (14 files)

Step 1 - Just looking, not fixing yet
Before touching anything, I opened all 14 files and wrote down what each one had: column names, how many rows, and anything that looked wrong (blanks, weird formats, spelling mistakes). I kept this separate from the actual files, in its own tracking sheet, so I wouldn't lose track of what I found.

Step 2 - Linking customers to vehicles (the master ID map)
The problem: complaints know a customer's ID and vehicle number. Warranty claims know the vehicle number and chassis number. Job cards know the chassis number and a scrambled phone number. No single file has all four pieces together.

I connected these like a chain: complaints - (matched by vehicle number) - warranty claims - (matched by chassis number) → job cards. This gave me one clean list linking all four IDs together for each customer/vehicle.

I did this in Power Query in PowerBI tool to properly merge big tables together. I loaded each file in, kept only the ID columns I needed, stacked the two years of complaints together, then linked them step by step to warranty claims and then job cards.

*What I found: most complaints (about 77%) never turned into an actual warranty claim, and even fewer (94% missing) made it all the way to a job card. This makes sense -  not every complaint means a part actually broke and needed a warranty claim.

Getting the file out was surprisingly hard.
Power BI kept only showing me a small preview instead of the full data whenever I tried to copy or export it. I eventually used a separate tool (DAX Studio) to properly pull out the whole thing and save it as a proper file.

 Step 3 - Fixing the old system's column names
One file (the old "legacy" sales records) used short, uncleaned column names and model codes from before the company switched systems. I renamed everything to match the current system's naming, and decoded the model codes (like "SP" really means "S1 Pro").

Step 4 - Making every date look the same
Different files stored dates in different formats - some day-first, some month-first, some with 2-digit years, some with 4-digit years, and a couple of files even had a mix of *both* formats in the same column. I went through and converted every date, in every file, into one consistent format.

One file also had a strange issue: about 5% of its dates were stored as a big meaningless number instead of an actual date (this is called an "epoch timestamp" - basically a count of seconds since 1970). I had to detect those specific rows and convert them properly.

Where a date was genuinely missing - like a complaint that's still open and hasn't been resolved yet - I left it truly blank rather than making something up. A blank resolution date doesn't mean bad data, it just means the ticket is still open.

Step 5 - Removing duplicates

Duplicate complaint tickets: About 2% of complaint tickets showed up more than once, sometimes with different statuses (like one copy saying "Open" and another saying "Resolved"). 
Ranking status priority" means: among the duplicate rows for one ticket_id, I kept only the one row with the highest-priority status, and delete the rest - regardless of what those other statuses are.

The priority order (customer-first, from the brief) is:
ESCALATED > OPEN/IN_PROGRESS > RESOLVED/CLOSED

What I did practically, example: say ticket_id = TKT00123 appears 2 times:

Row 1: status = RESOLVED
Row 2: status = ESCALATED

I  kept Row 2 (ESCALATED, higher priority) and deleted Row 1 (RESOLVED, lower priority)- not because RESOLVED is "bad," but because ESCALATED represents the more urgent, more current state of that ticket, and the brief's rule says when there's a conflict, so kept the more Urgent as ESCALTED 
status.

But if the same ticket_id appeared as, say, OPEN and RESOLVED (no ESCALATED involved) - I kept the OPEN row and delete the RESOLVED one, since OPEN is urgent than  RESOLVED in this priority order too.

I added a helper column that assigns a priority number to each status: =IF(status="ESCALATED",1, IF(OR(status="OPEN",status="IN_PROGRESS"),2, IF(OR(status="RESOLVED",status="CLOSED"),3, 4)))
Sorted the data by ticket_id, then by this priority number (ascending - 1 first).
For each ticket_id group, kept only the first row (lowest priority number = highest actual priority), delete the rest. I did this with Remove Duplicates on just the ticket_id column (after this sort), since Remove Duplicates keeps the first occurrence of each duplicate key.

Overlapping 2023 sales records: The company had two sales-tracking systems in 2023 - an old one and a new one - and both systems recorded a lot of the *same* sales. To find and remove the overlap, I built a matching label for each sale - combining the date, the city, and the model together into one identifier - in both files. Then I checked: does this same combination exist in the new system too? If yes, and both systems agreed on how many units were sold, it's a plain duplicate - I removed it from the old file, since the new system already has it. If the two systems disagreed on the quantity sold, that's a genuine conflict following the rule "the new system wins," I removed that row from the old file too. Only the sales that existed ONLY in the old system (about 9% of it) got kept and added into the final combined file. This meant the old and new sales files no longer overlapped - one clean, final 2023 sales dataset.

Wrong turnaround-time numbers: The complaint files had a "days to resolve" column that the project brief warned might be unreliable. I recalculated it myself directly from the two real dates (when the complaint came in vs. when it got resolved), and compared my recalculated number against the original column. In the 2023 file, over half didn't match the original number, and a big chunk showed impossible negative numbers (meaning the resolution date was somehow earlier than the complaint date — a real data problem). The 2024 file was noticeably cleaner and more trustworthy by comparison.

 Step 6 - Dealing with missing information
Some columns had missing values that couldn't just be guessed or filled in - like a customer satisfaction score that was never collected, or a severity level nobody assigned. For number-type columns (like satisfaction scores), I left them truly blank rather than making up a score. For label-type columns (like severity), I marked them clearly as "not specified" so it's obvious the information is genuinely missing, not zero or wrong.

Step 7 - Fixing currency
A small portion of warranty claims (about 2%) were recorded in US dollars instead of rupees, since some parts (like imported battery cells) are priced internationally. I converted those specific rows to rupees using a fixed exchange rate, and marked which rows were converted so it's always traceable later.

 Step 8 - Cleaning up city names and unstructured text
Many files spelled the same city differently - Bangalore vs Bengaluru, Bombay vs Mumbai, and so on. I built one master list mapping every variant to its correct, standard spelling, and applied it everywhere a city appeared.

For a text-heavy column (customer complaint descriptions), about 40-60% of rows (depending on the year) never had their "component" (what part of the vehicle the complaint was about) properly tagged. I planned to fill this in by searching the complaint text for certain keywords (like "brake," "battery," "charger") and assigning a category based on the first matching keyword - but decided to do this step later, using the database tool instead of Excel, since it does the same job.

I also converted two files that were in a different format (JSON, a nested/structured text format, not a spreadsheet) into regular spreadsheet files using an outside conversion tool, then cleaned them the same way.


Part 2: Putting everything into a proper database

Once the files were clean, I moved everything into a real database (PostgreSQL) and created staging_files and imported all these data, Then created dim tables and fact tables and their corresposnging primary key and foriegn key. I took help of connecting tables by looking at Schema table that brief mentioned.

Once everything was loaded and connected properly, I wrote a set of queries to actually answer business questions - monthly sales trends, which cities have the worst service coverage, which parts fail most often and cost the most in warranty claims, how market share has shifted over time compared to competitors. I also set up basic access rules (who can just view the data vs. who can also make changes) and demonstrated how to safely undo a mistake mid-transaction without losing other legitimate changes.

---

 Key findings so far
- Most complaints never turn into a formal warranty claim or job card  - only a small fraction of vehicles can be fully traced end-to-end across all systems.
- The old and new sales systems overlapped heavily for 2023 - about 90% of the old system's records were already duplicated in the new system, and about 1.4% had genuinely conflicting numbers.
- The complaint files' built-in "days to resolve" numbers can't be trusted - I had to recalculate this from scratch, and found the 2023 data was noticeably messier (more mismatches, more impossible negative values) than 2024, suggesting the company's data tracking improved over that year.
- Customer satisfaction scores are missing more often than expected - likely because complaints that are still open, or were closed early in their lifecycle (not yet resolved), naturally don't have a satisfaction score yet.
- Currency and city-name inconsistencies were real but manageable - a small, fixable percentage of rows needed correcting.
