# PostgreSQL VM → Cloud SQL Continuous Migration

Ye Google Cloud lab ke liye Cloud Shell automation hai. Script source VM `postgresql-vm` ka **internal IP** khud detect karta hai, `import_admin` credentials se PostgreSQL source connection profile banata hai, existing Cloud SQL instance `postgres86-iv8ej` ko destination profile ke roop me register karta hai, default VPC ke saath **VPC peering** use karke **continuous** migration job create karta hai, verify/test karta hai, aur job start karta hai.

## Cloud Shell me ye 3 commands one-by-one chalao

```bash
curl -LO https://raw.githubusercontent.com/manavyugaitech/Welcome/main/Migrate%20a%20stand-alone%20PostgreSQL%20database%20to%20Cloud%20SQL%20for%20PostgreSQL/Meow.sh
```

```bash
sudo chmod +x Meow.sh
```

```bash
./Meow.sh
```

## Expected time

Script ko aam taur par **5–10 minutes** lag sakte hain. DMS destination private IP allocation, VPC peering, initial full load, aur lab grader ke update ke hisaab se total completion **10–20 minutes** tak ho sakti hai. Script ke end me migration job ka state/phase print hoga; `RUNNING` ya equivalent active state aane par continuous migration start ho chuki hai.

## Important

- Script sirf temporary Skills Boost lab project me chalao.
- Source VM pehle se prepare honi chahiye: `pglogical`, logical replication settings, aur `import_admin` user/permissions lab ke previous task ke mutabik configured hon.
- Agar job verify karte waqt source PostgreSQL ke `pg_hba.conf` me DMS ke allocated peering CIDR ki zaroorat bataye, to lab ke VPC Peering effective route me dikhne wala CIDR `pg_hba.conf` me add karke PostgreSQL reload/restart karo, phir script dobara chalao.
- Temporary lab password script me included hai; lab khatam hone ke baad ye credentials expire ho jayenge.
