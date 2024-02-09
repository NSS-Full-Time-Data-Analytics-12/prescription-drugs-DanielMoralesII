--1.How many npi numbers appear in the prescriber table but not in the prescription table?


SELECT COUNT(npi) AS total_count_npi_not_in_prescription
FROM prescriber 
LEFT JOIN prescription USING (npi)
WHERE prescription.npi IS NULL;

-- Answer: 4458

--2a. Find the top five drugs (generic_name) prescribed by prescribers with the specialty of Family Practice.

SELECT generic_name, SUM(total_claim_count) AS total_claim
FROM prescription
INNER JOIN prescriber USING (npi)
INNER JOIN drug USING (drug_name)
WHERE specialty_description = 'Family Practice'
GROUP BY generic_name
ORDER BY total_claim DESC
LIMIT 5;

-- Answer: Run above query

--2b. Find the top five drugs (generic_name) prescribed by prescribers with the specialty of Cardiology.

SELECT generic_name, SUM(total_claim_count) AS total_claim
FROM prescription
INNER JOIN prescriber USING (npi)
INNER JOIN drug USING (drug_name)
WHERE specialty_description = 'Cardiology'
GROUP BY generic_name
ORDER BY total_claim DESC
LIMIT 5;

-- Answer: Run above query

--2c. Which drugs are in the top five prescribed by Family Practice prescribers and Cardiologists? 
--Combine what you did for parts a and b into a single query to answer this question.


SELECT generic_name, SUM(total_claim_count) AS total_claim
FROM prescription
INNER JOIN prescriber USING (npi)
INNER JOIN drug USING (drug_name)
WHERE specialty_description = 'Family Practice' OR specialty_description = 'Cardiology'
GROUP BY generic_name
ORDER BY total_claim DESC
LIMIT 5;

-- Answer: Run above query

-- Your goal in this question is to generate a list of the top prescribers in each of the major metropolitan areas of Tennessee.

--3a. First, write a query that finds the top 5 prescribers in Nashville in terms of the total number of claims (total_claim_count) 
--across all drugs. Report the npi, the total number of claims, and include a column showing the city.

WITH nashville_prescribers AS (SELECT DISTINCT npi, nppes_provider_city
								FROM prescriber
								WHERE nppes_provider_city ILIKE '%NASHVILLE%')

SELECT npi, SUM(total_claim_count) AS total_claim_count, nppes_provider_city
FROM prescription RIGHT JOIN nashville_prescribers USING (npi)
GROUP BY npi, nppes_provider_city
ORDER BY total_claim_count DESC NULLS LAST
LIMIT 5;

-- Answer: Run above query

--3b. Now, report the same for Memphis.

WITH memphis_prescribers AS (SELECT DISTINCT npi, nppes_provider_city
								FROM prescriber
								WHERE nppes_provider_city ILIKE '%MEMPHIS%')

SELECT npi, SUM(total_claim_count) AS total_claim_count, nppes_provider_city
FROM prescription RIGHT JOIN memphis_prescribers USING (npi)
GROUP BY npi, nppes_provider_city
ORDER BY total_claim_count DESC NULLS LAST
LIMIT 5;

-- Answer: Run above query
								
--3c. Combine your results from a and b, along with the results for Knoxville and Chattanooga.

(WITH nashville_prescribers AS (SELECT DISTINCT npi, nppes_provider_city
								FROM prescriber
								WHERE nppes_provider_city ILIKE '%NASHVILLE%')

SELECT npi, SUM(total_claim_count) AS total_claim_count, nppes_provider_city
FROM prescription RIGHT JOIN nashville_prescribers USING (npi)
GROUP BY npi, nppes_provider_city
ORDER BY total_claim_count DESC NULLS LAST
LIMIT 5)
UNION
(WITH memphis_prescribers AS (SELECT DISTINCT npi, nppes_provider_city
								FROM prescriber
								WHERE nppes_provider_city ILIKE '%MEMPHIS%')

SELECT npi, SUM(total_claim_count) AS total_claim_count, nppes_provider_city
FROM prescription RIGHT JOIN memphis_prescribers USING (npi)
GROUP BY npi, nppes_provider_city
ORDER BY total_claim_count DESC NULLS LAST
LIMIT 5)
UNION
(WITH chattanooga_prescribers AS (SELECT DISTINCT npi, nppes_provider_city
								FROM prescriber
								WHERE nppes_provider_city ILIKE '%CHATTANOOGA%')

SELECT npi, SUM(total_claim_count) AS total_claim_count, nppes_provider_city
FROM prescription RIGHT JOIN chattanooga_prescribers USING (npi)
GROUP BY npi, nppes_provider_city
ORDER BY total_claim_count DESC NULLS LAST
LIMIT 5)
UNION
(WITH knoxville_prescribers AS (SELECT DISTINCT npi, nppes_provider_city
								FROM prescriber
								WHERE nppes_provider_city ILIKE '%KNOXVILLE%')
								
SELECT npi, SUM(total_claim_count) AS total_claim_count, nppes_provider_city
FROM prescription RIGHT JOIN knoxville_prescribers USING (npi)
GROUP BY npi, nppes_provider_city
ORDER BY total_claim_count DESC NULLS LAST
LIMIT 5)
ORDER BY nppes_provider_city, total_claim_count DESC;

-- Answer: Run above query

--4. Find all counties which had an above-average number of overdose deaths. Report the county name and number of overdose deaths.

--AVG 12.61

WITH above_average_overdoses AS (SELECT *
									FROM overdose_deaths
									WHERE overdose_deaths > (SELECT ROUND(AVG(overdose_deaths),2)FROM overdose_deaths))
							 
SELECT county, year, overdose_deaths
FROM fips_county RIGHT JOIN above_average_overdoses ON fips_county.fipscounty::integer = above_average_overdoses.fipscounty;

-- Answer: Run above query

--5a. Write a query that finds the total population of Tennessee.

SELECT SUM(population) AS total_tn_pop
FROM population INNER JOIN fips_county USING (fipscounty);

-- Answer: 6,597,381

--5b. Build off of the query that you wrote in part a to write a query that returns for each county that county's name, its 
-- population, and the percentage of the total population of Tennessee that is contained in that county.

SELECT county, population, ROUND(population/(SELECT SUM(population) FROM population) * 100,2) AS percent_of_pop
FROM population LEFT JOIN fips_county USING (fipscounty)
ORDER BY percent_of_pop DESC;

-- Answer: Run above query


