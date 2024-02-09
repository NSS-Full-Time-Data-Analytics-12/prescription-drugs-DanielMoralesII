--1. a. Which prescriber had the highest total number of claims (totaled over all drugs)? Report the npi and the total number of claims.

SELECT npi, SUM(total_claim_count)AS total_claims 
FROM prescription
GROUP BY npi
ORDER BY total_claims DESC;

--Answer: Highest total # of claims - npi 1881634483, total_claims 99707

--b. Repeat the above, but this time report the nppes_provider_first_name, nppes_provider_last_org_name,  specialty_description, and the 
--total number of claims.

SELECT nppes_provider_first_name, nppes_provider_last_org_name,specialty_description,SUM(total_claim_count)AS total_claims 
FROM prescription
INNER JOIN prescriber USING (npi)
GROUP BY npi, nppes_provider_first_name, nppes_provider_last_org_name, specialty_description
ORDER BY total_claims DESC;

--Answer: Highest total # of claims - BRUCE PENDLEY, "Family Practice",  total_claims 99707

--2a. Which specialty had the most total number of claims (totaled over all drugs)?

SELECT specialty_description, SUM(total_claim_count)AS total_claims
FROM prescription
INNER JOIN prescriber USING (npi)
GROUP BY specialty_description
ORDER BY total_claims DESC;

-- Answer: "Family Practice", total claims 9752347

--2b. Which specialty had the most total number of claims for opioids?

SELECT specialty_description, SUM(total_claim_count)AS total_claims, opioid_drug_flag
FROM prescription
INNER JOIN prescriber USING (npi)
INNER JOIN drug USING (drug_name)
WHERE opioid_drug_flag = 'Y'
GROUP BY specialty_description, opioid_drug_flag
ORDER BY total_claims DESC;

-- Answer: Nurse Practicioner, total claims 900845

--2c. **Challenge Question:** Are there any specialties that appear in the prescriber table that have no 
--associated prescriptions in the prescription table?

-- 92 specialty descriptions in prescription
-- 107 distinct specialty_description in prescriber
-- Answer should be 15 rows

SELECT specialty_description
FROM prescriber
LEFT JOIN prescription USING (npi)
GROUP BY specialty_description
EXCEPT
SELECT specialty_description
FROM prescription
INNER JOIN prescriber USING (npi)
GROUP BY specialty_description;

-- Answer: Run above query


--3a. Which drug (generic_name) had the highest total drug cost?

SELECT generic_name, SUM(total_drug_cost::money) AS total_drug_cost
FROM prescription
INNER JOIN drug USING (drug_name)
GROUP BY generic_name
ORDER BY total_drug_cost DESC;

-- Answer: "INSULIN GLARGINE,HUM.REC.ANLOG"

--3b. Which drug (generic_name) has the hightest total cost per day? **Bonus: Round your cost per day column to 2 decimal places. 
--Google ROUND to see how this works.**

SELECT generic_name, ROUND(SUM(total_drug_cost)/SUM(total_day_supply),2) AS cost_per_day
FROM prescription
INNER JOIN drug USING (drug_name)
GROUP BY generic_name
ORDER BY cost_per_day DESC;

-- Answer: "C1 ESTERASE INHIBITOR", 3495.22

--4a. For each drug in the drug table, return the drug name and then a column named 'drug_type' which says 'opioid' for drugs 
-- which have opioid_drug_flag = 'Y', says 'antibiotic' for those drugs which have antibiotic_drug_flag = 'Y', and says 'neither' for all other drugs.

SELECT drug_name, 
CASE WHEN opioid_drug_flag = 'Y' THEN 'opioid'
	 WHEN antibiotic_drug_flag = 'Y' THEN 'antibiotic'
	 ELSE 'neither' END AS drug_type
FROM drug
ORDER BY drug_type;

--Answer: Run query above

--4b. Building off of the query you wrote for part a, determine whether more was spent (total_drug_cost) on opioids or on antibiotics. 
--Hint: Format the total costs as MONEY for easier comparision.

SELECT SUM(total_drug_cost::money) AS total_drug_cost,
CASE WHEN opioid_drug_flag = 'Y' THEN 'opioid'
	 WHEN antibiotic_drug_flag = 'Y' THEN 'antibiotic'
	 ELSE 'neither' END AS drug_type
FROM prescription
INNER JOIN drug USING (drug_name)
GROUP BY drug_type, opioid_drug_flag, antibiotic_drug_flag
ORDER BY total_drug_cost DESC;

--Answer: Opioids

--5a.How many CBSAs are in Tennessee? **Warning:** The cbsa table contains information for all states, not just Tennessee.

-- 1238 total rows
-- 409 distinct cbsa

SELECT DISTINCT(cbsa),cbsaname
FROM cbsa
WHERE cbsaname LIKE '%TN%'
ORDER BY cbsa;

--Answer: 10

--5b.Which cbsa has the largest combined population? Which has the smallest? Report the CBSA name and total population.

SELECT DISTINCT(cbsa), cbsaname, SUM(population) AS tot_pop
FROM cbsa
INNER JOIN fips_county USING (fipscounty)
INNER JOIN population USING (fipscounty)
WHERE cbsaname LIKE '%TN%'
GROUP BY DISTINCT(cbsa), cbsaname
ORDER BY tot_pop DESC;

--Answer: Largest "Nashville-Davidson--Murfreesboro--Franklin, TN", tot_pop 1830410 /Smallest "Morristown, TN", tot-pop 116352

--5c. What is the largest (in terms of population) county which is not included in a CBSA? Report the county name and population.

SELECT county, population, cbsa
FROM population
LEFT JOIN fips_county USING (fipscounty)
LEFT JOIN cbsa USING (fipscounty) 
WHERE cbsa IS NULL 
ORDER BY population DESC;

--Answer: "SEVIER", population 95523

--6a. Find all rows in the prescription table where total_claims is at least 3000. Report the drug_name and the total_claim_count.

SELECT drug_name, total_claim_count
FROM prescription
WHERE total_claim_count >= 3000
GROUP BY drug_name, total_claim_count;

--Answer: Run query above; 9 total drugs with at least 3000 total claims.

--6b. For each instance that you found in part a, add a column that indicates whether the drug is an opioid.

SELECT prescription.drug_name, total_claim_count, opioid_drug_flag AS is_this_an_opioid
FROM prescription
INNER JOIN drug USING (drug_name)
WHERE total_claim_count >= 3000
GROUP BY prescription.drug_name, opioid_drug_flag, total_claim_count;

--Answer: Run query above; Only 2 out of the 9 total drugs with at least 3000 total claims were opioids.

--6c. Add another column to your answer from the previous part which gives the prescriber first and last name associated with each row.

SELECT prescription.drug_name, nppes_provider_first_name || ' '||  nppes_provider_last_org_name AS prescriber_name,
SUM(total_claim_count), opioid_drug_flag AS is_this_an_opioid
FROM prescription
INNER JOIN drug USING (drug_name)
INNER JOIN prescriber USING (npi)
WHERE total_claim_count >= 3000
GROUP BY prescription.drug_name, opioid_drug_flag, nppes_provider_first_name, nppes_provider_last_org_name;

--Answer: Run query above

--7. The goal of this exercise is to generate a full list of all pain management specialists in Nashville and the number of claims they had for 
-- each opioid. **Hint:** The results from all 3 parts will have 637 rows.

--7a. First, create a list of all npi/drug_name combinations for pain management specialists (specialty_description = 'Pain Managment') in the 
--city of Nashville (nppes_provider_city = 'NASHVILLE'), where the drug is an opioid (opiod_drug_flag = 'Y'). **Warning:** Double-check your 
--query before running it. You will only need to use the prescriber and drug tables since you don't need the claims numbers yet.

SELECT npi, drug_name
FROM prescriber
CROSS JOIN drug
WHERE specialty_description = 'Pain Management'
	AND nppes_provider_city = 'NASHVILLE'
	AND opioid_drug_flag = 'Y';
	
--Answer: Run query above
	
--7b. Next, report the number of claims per drug per prescriber. Be sure to include all combinations, whether or not the 
-- prescriber had any claims. You should report the npi, the drug name, and the number of claims (total_claim_count).

WITH nashville_opioids AS (SELECT npi, drug_name
						   FROM prescriber
						   CROSS JOIN drug
						   WHERE specialty_description = 'Pain Management'
						   		AND nppes_provider_city = 'NASHVILLE'
						   		AND opioid_drug_flag = 'Y')
SELECT npi, drug_name, total_claim_count
FROM prescription RIGHT JOIN nashville_opioids USING (drug_name,npi);

--Answer: Run query above

--7c. Finally, if you have not done so already, fill in any missing values for total_claim_count with 0. Hint - Google the COALESCE function.

WITH nashville_opioids AS (SELECT npi, drug_name
						   FROM prescriber
						   CROSS JOIN drug
						   WHERE specialty_description = 'Pain Management'
						   		AND nppes_provider_city = 'NASHVILLE'
						   		AND opioid_drug_flag = 'Y')
SELECT npi, drug_name, COALESCE(total_claim_count, '0')
FROM prescription RIGHT JOIN nashville_opioids USING (drug_name,npi);

--Answer: Run query above