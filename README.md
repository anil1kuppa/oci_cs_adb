# oci_cs_adb
This would create autonomous DB and the relevant tables required for [Algo Strategies](https://github.com/anil1kuppa/kha-ching)

Steps to follow
1. Go to [clould.oracle.com](cloud.oracle.com) and sign up for account. It gives free access to Oracle Autonomous DB. Preferably choose region as India-Hyderabad.
2. Click on cloud shell ![image](https://user-images.githubusercontent.com/24491456/150648801-51912bb9-3cac-4b04-973f-69dbe98f02c5.png)
3. Clone the GIT repository, git is pre-installed with OCI Cloud Shell:
<pre><code>git clone https://github.com/anil1kuppa/oci_cs_adb
</pre></code>
Change directory to the working directory and remove the remote origin. This is to avoid changes going to the GIT repository from OCI Cloud Shell. Feel free to create a branch and participate/improve the repo.
<pre><code>cd oci_cs_adb
git remote remove origin
</pre></code>

You should have the following files in the git working directory:

    env_vars.sh -- Set the environment variables
    create_atp_free.sh -- Creates an ADB (ATP)
    get_adb_ocid.sh -- Get's the OCID for the created ADB
    get_wallet.sh -- Get's the wallet for the created ATP
    get_conn_string.sh -- Ignore this file
    fix_sqlnet.sh --Fixes the SQLNet string
    create_user.sh --Creates the user 'SignalX'
    create_soda_collections.sh --Creates the SODA collections, tables and procedure
    soda_collections.sql --Contains the sql scripts for db objects creations
    README.md -- Ignore this file, Part of the Github repo


4. Run env_vars.sh You can see the below sample. The password should be of length between 12 to 30 and should contain 1 capital letter and 1 number alteast

<pre><code>source env_vars.sh
</pre></code>
![image](https://user-images.githubusercontent.com/24491456/151687637-496b6e7f-fa2d-4322-878b-16053df1a332.png)

5. Execute the command below to create an ADB (ATP - OLTP) in the root compartment specified with database SignlX. The admin password for the database is is specified in the variable db_pwd. 
<pre><code>source create_atp_free.sh
</pre></code>
This process might take few minutes . You can check the status of the creation of the ADB ATP Database using the script check_atp_status.sh or using the console.
The status should be available.
<pre><code>source check_atp_status.sh
</pre></code>
![image](https://user-images.githubusercontent.com/24491456/151687770-6a0b2519-05e1-47ff-8050-4568c7aa175a.png)

6. Get the OCID for DB: We are going to need the OCID for the ADB so we can download the Wallet files. Run the get_adb_ocid.sh command to get the OCID for the newly created ATP Database.
<pre><code>source get_adb_ocid.sh
</pre></code>
 ![image](https://user-images.githubusercontent.com/24491456/151687840-77d8ca0d-c087-4276-a089-5f164413f067.png)
7. Create the directory structure and download the wallet.
<pre><code>source get_wallet.sh
source fix_sqlnet.sh
</pre></code>
![image](https://user-images.githubusercontent.com/24491456/151687918-13b641a9-513a-40e8-a165-926f322e2bfc.png)
8. Create the user with same password as you'd entered earlier. The DB objects and collections would be created in this user's schema.
<pre><code>source create_user.sh
</pre></code>
![image](https://user-images.githubusercontent.com/24491456/151687952-4b9fd752-4a55-40b2-ac7b-59b4dfb043c5.png)

9. Create the collections and the DB objects. 
<pre><code>source create_soda_collections.sh
</pre></code>
![image](https://user-images.githubusercontent.com/24491456/151687992-0ac19ed4-d780-4b2b-bbf4-c72ca59b6fe0.png)

10. Print the SODA URL and copy (Ctlr+C) it. This will be used to set the environment variable _ORCL_HOST_URL_ in [khaching](https://github.com/anil1kuppa/kha-ching)
<pre><code>source  print_soda_url.sh
</pre></code>
It will look something like this: https://g13241234ani-signlx.adb.ap-hyderabad-1.oraclecloudapps.com/ords/signalx

**Do not share this URL with anyone as it's connection to DB. It will store the transactions, daily plans and executed plan.**
