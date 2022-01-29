# oci_cs_adb
This would create autonomous DB and the relevant tables required for [Algo Strategies](https://github.com/anil1kuppa/kha-ching)

Steps to follow
1. Go to [clould.oracle.com](cloud.oracle.com) and sign up for account. It gives free access to Oracle Autonomous DB.
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
    get_ocid_comp.sh -- Get's the OCID for the compartment
    create_atp_free.sh -- Creates an ADB (ATP)
    get_adb_ocid.sh -- Get's the OCID for the created ADB
    get_wallet.sh -- Get's the wallet for the created ATP
    get_conn_string.sh -- Ingore this file
    README.md -- Ignore this file, Part of the Github repo

Edit the env_vars.sh file using vim. You need to set the db_name variable in the script. Save the file.

<pre><code>vi env_vars.sh
</pre></code>

Enter DB Password. The password should be of length between 12 to 30 and should contain 1 capital letter and 1 number alteast

<pre><code>source env_vars.sh
</pre></code>

This will fetch the compartMentID

<pre><code>source get_ocid_comp.sh
</pre></code>




source create_atp_free.sh
source check_atp_status.sh
source get_adb_ocid.sh
source get_wallet.sh
source fix_sqlnet.sh
source create_user.sh
source create_soda_collections.sh
source print_soda_url.sh 
Note down the URL and enter in the environment variable 
