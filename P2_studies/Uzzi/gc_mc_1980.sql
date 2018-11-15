-- test script to test Monte-Carlo methods for networks
-- this script was specifically developed for the ERNIE project 
-- but can be used for benchmarking performance
-- George Chacko 10/25/2018

SELECT NOW();
DROP TABLE IF EXISTS gc_mc1;
CREATE TABLE gc_mc1 AS
SELECT source_id, publication_year AS source_year 
FROM wos_publications
WHERE publication_year::int = 1980
AND document_type='Article'; 
CREATE INDEX gc_mc1_idx ON gc_mc1(source_id);

-- join to get cited references. Expect to lose some data since not all 
-- pubs will have references that meet the WHERE conditions in this query
DROP TABLE IF EXISTS gc_mc2;
CREATE TABLE gc_mc2 AS
SELECT a.*,b.cited_source_uid
FROM gc_mc1 a INNER JOIN wos_references b 
ON a.source_id=b.source_id;
CREATE INDEX gc_mc2_idx ON gc_mc2(source_id,cited_source_uid);

DROP TABLE IF EXISTS gc_mc21;
CREATE TABLE gc_mc21 AS
SELECT * FROM gc_mc2
WHERE substring(cited_source_uid,1,4)='WOS:'
AND length(cited_source_uid)=19;
CREATE INDEX gc_mc21_idx ON gc_mc2(source_id,cited_source_uid);

DROP TABLE IF EXISTS gc_mc3;
CREATE TABLE gc_mc3 AS
SELECT a.*,b.publication_year AS reference_year
FROM gc_mc21 a INNER JOIN wos_publications b
ON a.cited_source_uid=b.source_id;
CREATE INDEX gc_mc3_idx ON gc_mc3(source_id,cited_source_uid,reference_year);

DROP TABLE IF EXISTS gc_mc4;
CREATE TABLE gc_mc4 AS
SELECT  a.*,b.document_id as reference_issn,b.document_id_type
FROM gc_mc3 a LEFT JOIN wos_document_identifiers b
ON a.cited_source_uid=b.source_id 
WHERE document_id_type='issn';
CREATE INDEX gc_mc4_idx ON gc_mc4(source_id,cited_source_uid,reference_year,reference_issn);

DROP TABLE IF EXISTS gc_mc5;
CREATE TABLE gc_mc5 AS
SELECT a.source_id,
a.source_year,
b.document_id AS source_issn,
b.document_id_type AS source_document_id_type,
a.cited_source_uid,
a.reference_year,
a.reference_issn,
a.document_id_type AS reference_document_id_type
FROM gc_mc4 a LEFT JOIN wos_document_identifiers b
ON a.source_id=b.source_id
WHERE b.document_id_type='issn';

CREATE INDEX gc_mc5_idx ON gc_mc5(source_id,cited_source_uid,reference_year,reference_issn,source_issn,
source_year);

DROP TABLE IF EXISTS gc_mc_1980;
CREATE TABLE gc_mc_1980 AS
SELECT DISTINCT * from gc_mc5;
CREATE INDEX gc_mc_1980_idx ON gc_mc_1980(source_id,cited_source_uid,source_issn,reference_issn);

\copy (SELECT * FROM gc_mc_1980) TO '/erniedev_data5/P2_studies/chackoge/data1980.csv' DELIMITER ',' CSV HEADER;

DROP TABLE gc_mc1;
DROP TABLE gc_mc2;
DROP TABLE gc_mc21;
DROP TABLE gc_mc3;
DROP TABLE gc_mc4;
DROP TABLE gc_mc5;

SELECT NOW();