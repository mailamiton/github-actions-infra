import os
import json
import logging
import argparse
from dotenv import load_dotenv
from dbt.cli.main import dbtRunner, dbtRunnerResult

def get_dbt_directory():
    """
    Returns the working directory of dbt so that the run command can run from any directory.
    """
    curr_dir = os.getcwd()
    while True:
        dbt_path = os.path.join(curr_dir, "dbt/")
        if os.path.exists(dbt_path) and os.path.isdir(dbt_path):
            logging.info("dbt path exists.")
            return dbt_path
        parent_path = os.path.dirname(curr_dir)
        if parent_path == curr_dir:
            logging.error("dbt path is not found")
            raise FileNotFoundError("Could not find dbt folder.")
        curr_dir = parent_path

def run_dbt(target: str, full_refresh: bool):
    """
    Changes into the dbt project directory and invokes a dbt command.
    """
    logging.info("Running dbt process.")
    dbt_directory = get_dbt_directory()
    # dbt commands must be run from within the dbt project directory
    os.chdir(dbt_directory)
    
    dbt = dbtRunner()

    # Build the dbt command
    cli_args = ["run", "--target", target]
    if full_refresh:
        cli_args.append("--full-refresh")
    
    # Point to the profiles.yml within this directory
    cli_args.extend(["--profiles-dir", "."])

    logging.info(f"Invoking dbt with: {cli_args}")
    res: dbtRunnerResult = dbt.invoke(cli_args)

    for r in res.result:
        logging.info(f"{r.node.name}: {r.status}")
   
    if not res.success:
        logging.error("DBT failed with error.")
        raise RuntimeError("DBT failed with error, see logs for more detail.")
    else:
        logging.info("DBT run completed successfully.")

if __name__ == '__main__':
    load_dotenv()
    logging.basicConfig(level=logging.INFO)

    parser = argparse.ArgumentParser(description="A Python wrapper for running dbt.")
    parser.add_argument("--target", default="dev", type=str, help="The dbt target to use.")
    parser.add_argument("--full-refresh", action="store_true", help="Perform a full refresh.")
    args = parser.parse_args()

    run_dbt(target=args.target, full_refresh=args.full_refresh)
