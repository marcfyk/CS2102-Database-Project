1. This website uses Flask as its backend. The developer used Python 3.7.3
   to run the website
2. cd into `website` and run `pip install -r requirements.txt`
3. cd into `sql_scripts`
4. run `sql_setUpDB.sql` using psql. On windows CMD, this can be
   done with `psql -f sql_setUpDB.sql`
5. `cd ..` back into `website`.
6. Run the Flask app

>> On Windows CMD
cd website
set FLASK_APP=application
flask run

>> MAC
run `python application.py`
