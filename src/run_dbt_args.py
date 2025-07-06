import os
import json
from dotenv import load_dotenv
import argparse
import logging
from dbt.cli.main import dbtRunner, dbtRunnerResult


def get_dbt_directory():
    """
    Returns the working directory of dbt so that the run command can run from any directory
    """
    curr_dir = os.getcwd()
    while True:
        dbt_path = os.path.join(curr_dir, "dbt/")
        if os.path.exists(dbt_path) and os.path.isdir(dbt_path):
            logging.info("dbt path exists.")
            return dbt_path
        parent_path = os.path.dirname(curr_dir)
        if parent_path == curr_dir:
            logging.info("dbt path is not found")
            raise FileNotFoundError("Could not find dbt folder.")
        curr_dir = parent_path


def run_dbt(target, full_refresh, vars):
    logging.info("Running dbt process.")
    dbt_directory = get_dbt_directory()
    os.chdir(dbt_directory)
    dbt = dbtRunner()
    
    target_tag = f"tag:{target}"
    logging.info(f"dbt target {target}")
    vars = vars

    # create CLI args as a list of strings
    # TODO: this would need to change based off of the kinds of command line args you are looking to accept
    if full_refresh:
        cli_args = ["run", "--target", target, "--select", target_tag, "--full-refresh"]
    else:
        cli_args = ["run", "--target", target, "--select", target_tag]

    logging.info(f"cli args: {cli_args}")

    # run the command
    res: dbtRunnerResult = dbt.invoke(cli_args)
    
    # inspect the results
    for r in res.result:
        logging.info(f"{r.node.name}: {r.status}")
        print(f"{r.node.name}: {r.status}")
   
    if res.success is not True:
        raise RuntimeError("DBT failed with error, see logs for more detail.")


if __name__ == '__main__':
    load_dotenv()
    
    logger = logging.getLogger()
    
    parser = argparse.ArgumentParser()
    parser.add_argument("--target", default=None)
    parser.add_argument("--full-refresh", action="store_true", default=None)
    args = parser.parse_args()
    vars = None

    run_dbt(args.target, args.full_refresh, vars)
