"""Convert the CMS ICD-10-CM codes file into a CSV for import into Supabase.

Input:  icd10cm_codes_2027.txt (code in the first 7 characters, description after)
Output: icd10_codes.csv with columns: code, description
"""
import csv

n = 0
with open("icd10cm_codes_2027.txt", encoding="utf-8") as f, \
     open("icd10_codes.csv", "w", newline="", encoding="utf-8") as out:
    w = csv.writer(out)
    w.writerow(["code", "description"])
    for line in f:
        w.writerow([line[:7].strip(), line[8:].strip()])
        n += 1

print("Rows written:", n)
