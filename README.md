# oci_cs_adb
This would create autonomous DB and the relevant tables required for [Algo Strategies](https://github.com/anil1kuppa/kha-ching)

Steps to follow
1. Go to clould.oracle.com and sign up for account. It gives free access to Oracle Autonomous DB.
2. Click on cloud shell ![image](https://user-images.githubusercontent.com/24491456/150648801-51912bb9-3cac-4b04-973f-69dbe98f02c5.png)
3. Clone the GIT repository, git is pre-installed with OCI Cloud Shell:

anilkuppa@cloudshell:~ (ap-seoul-1)$ git clone https://github.com/anil1kuppa/oci_cs_adb

Change directory to the working directory and remove the remote origin. This is to avoid changes going to the GIT repository from OCI Cloud Shell. Feel free to create a branch and participate/improve the repo.

anilkuppa@cloudshell:~ (ap-seoul-1)$ cd oci_cs_adb
anilkuppa@cloudshell:~ (ap-seoul-1)$ git remote remove origin

You should have the following files in the git working directory:

    env_vars.sh -- Set the environment variables
    get_ocid_comp.sh -- Get's the OCID for the compartment
    create_atp_free.sh -- Creates an ADB (ATP)
    get_adb_ocid.sh -- Get's the OCID for the created ADB
    get_wallet.sh -- Get's the wallet for the created ATP
    get_conn_string.sh -- Ingore this file
    README.md -- Ignore this file, Part of the Github repo

Edit the env_vars.sh file using vim. You need to set the db_name variable in the script. Save the file.

anilkuppa@cloudshell:~ (ap-seoul-1)$ vi env_vars.sh


These scripts are to support the following [blog post](https://sunrise-flier-24f.notion.site/Create-Autonomous-DB-in-OCI-d714d8d0c41443d0a756961b9a3316e2)


