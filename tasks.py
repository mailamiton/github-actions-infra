from dotenv import load_dotenv
from invoke import Context, task 

@task 
def test_dbt(c: Context, full_refresh=False) -> None: 
    # load_dotenv()

    command = f"python -m  src.run_dbt"

    #TODO: can you

    c.run(command)