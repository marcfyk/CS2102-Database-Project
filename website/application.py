from os import path
from ast import literal_eval
from flask_sqlalchemy import SQLAlchemy
from flask_login import LoginManager, current_user, login_required, login_user
from psql_setting import get_db_settings_string
from functools import wraps
from flask import (
    Flask, flash, g, jsonify, redirect, render_template,
    request, session, url_for, Blueprint
)
import json
import sqlite3
import re
import datetime
import pprint

pp = pprint.PrettyPrinter(indent=4)

app = Flask(__name__)

# To run properly -> configure dotenv.py to your own PSQL settings
app.config['SQLALCHEMY_DATABASE_URI'] = get_db_settings_string()
app.config['SECRET_KEY'] = 'A random key to use CRF for forms'
db = SQLAlchemy()
login_manager = LoginManager()
db.init_app(app)
login_manager.init_app(app)

ROOT = path.dirname(path.realpath(__file__))

def login_required(f):
    @wraps(f)
    def decorated_function(*args, **kwargs):
        if session.get("username") is None:
            return redirect("/login")
        return f(*args, **kwargs)
    return decorated_function

"""
ROUTES
"""
@app.route("/")
def index():
    return render_template("index.html")

@app.route("/projects", methods = ["GET"])
def projects():
    query = "SELECT * FROM Project"
    data = db.session.execute(query).fetchall()
    return render_template("projects.html", data=data)

@app.route("/signup", methods=["GET", "POST"])
def signup():
    if request.method == "POST":
        form = request.form
        username = form["username"]
        password = form["password"]
        email = form["email"]
        query = f"SELECT * FROM Account WHERE username = '{username}'"
        user_exists = db.session.execute(query).fetchone()
        if user_exists:
            flash("That username already exists...")
            return render_template("signup.html")
        else:
            query = f"INSERT INTO Account(username, password, email) VALUES ('{username}', '{password}', '{email}')"
            db.session.execute(query)
            db.session.commit()
            flash("Registered! Please sign-in to your account.")
            return render_template("index.html")
    else:
        return render_template("signup.html")

@app.route("/login", methods=["GET", "POST"])
def login():
    session.clear()
    if request.method == "POST":
        form = request.form
        username = form["username"]
        password = form["password"]
        query = f"SELECT * FROM Account WHERE username = '{username}' AND password = '{password}'"
        user_exists = db.session.execute(query).fetchone()
        if user_exists:
            flash(f"Welcome, {username}.")
            session["username"] = username
            return render_template("index.html")
        else:
            flash("Sorry, that username does not exist.")
    return render_template("login.html")

@app.route("/logout")
def logout():
    session.clear()
    flash("Logged out.")
    return redirect("/")

@app.route("/profile")
def profile():
    user = session["username"]
    query = f"SELECT P.name, P.creation_date, P.expiration_date, P.goal, \
        P.funds, P.rating FROM Project P, Owns O WHERE O.username='{user}' \
        AND P.projectId = O.projectId"
    result = db.session.execute(query).fetchone()
    return render_template("profile.html", data=result)

@app.route("/new_project", methods=["GET", "POST"])
@login_required
def new_project():
    if request.method == "POST":
        form = request.form

        data = {
            "project_name":    form["project-name"],
            "expiration_date": form["expiration-date"],
            "goal":            form["goal"],
            "product_name":    form["product-name"],
            "product_price":   form["product-price"],
            "product_desc":    form["product-description"]
        }

        query = "SELECT 1 FROM Project WHERE name='{}'".format(data["project_name"])
        project_exists = db.session.execute(query).fetchone()
        if project_exists:
            flash("That project name is already taken.")
            return render_template("new_project.html")
        else:
            now = datetime.date.today()
            data["creation_date"] = str(now)
            query = "INSERT INTO Project(name, expiration_date, goal) VALUES ('{}', '{}', '{}')" \
                .format(
                    data["project_name"],
                    data["expiration_date"],
                    data["goal"]
                )
            db.session.execute(query)
            db.session.commit()
            return redirect(url_for("render_project_page", data=data))
    else:
        return render_template("new_project.html")

@app.route("/get_project", methods=["GET", "POST"])
def get_project():
    if request.method == "POST":
        name = request.get_json()["name"]
        query = "SELECT * FROM Project WHERE name='{}'".format(name)
        ret = db.session.execute(query).fetchone()
        query = "SELECT * FROM Product WHERE projectId={}".format(ret[0])
        ret2 = db.session.execute(query).fetchone()

        for i in ret:
            print(i)
        for i in ret2:
            print(i)

        data = {
            "project_name": ret[1],
            "creation_date": ret[2],
            "expiration_date": ret[3],
            "product_name": ret2[0],
            "product_price": ret2[3],
            "product_desc": ret2[2]
        }
        print(data)

        return redirect(url_for("render_project_page", data=data))
    return render_template("projects.html")

@app.route("/project_page", methods=["GET"])
def render_project_page():
    data = literal_eval(request.args["data"]) # convert to python dict
    return render_template("project_page.html", data=data)

@app.route("/credit_card", methods=["GET", "POST"])
@login_required
def credit_card():
    if request.method == "POST":
        form = request.form
        cc_number = form["cc-number"]
        cc_expire_mm = form["cc-expire-mm"]
        cc_expire_yy = form["cc-expire-yy"]
        cc_expire_date = "{}-{}-01".format(cc_expire_yy, cc_expire_mm)
        query = "SELECT 1 FROM HasCreditCard WHERE username='{}' AND number='{}'".format(
            session["username"], cc_number
        )
        cc_exists = db.session.execute(query).fetchone()
        if cc_exists:
            flash("You already have that credit card!")
            return render_template("credit_card.html")
        else:
            query = "INSERT INTO CreditCard(number, exp) VALUES ('{}', '{}')".format(
                cc_number, cc_expire_date
            )
            query2 = "INSERT INTO HasCreditCard(username, number) VALUES('{}', '{}')".format(
                session["username"], cc_number
            )
            db.session.execute(query)
            db.session.execute(query2)
            db.session.commit()
            flash("Credit Card saved.")
            return render_template("credit_card.html")
    else:
        return render_template("credit_card.html")

@app.route("/address", methods=["GET", "POST"])
@login_required
def address():
    if request.method == "POST":
        form = request.form
        addr = form["address"]
        country = form["country"]

        query = "SELECT 1 FROM HasAddress WHERE username='{}' \
                AND country='{}' AND location='{}'".format(
            session["username"],
            country,
            addr
        )
        exists = db.session.execute(query).fetchone()
        if exists:
            flash("Address already in your profile.")
            return render_template("address.html")
        else:
            query = "INSERT INTO Address(country, location) VALUES ('{}', '{}')".format(
                country, addr
            )
            query2 = "INSERT INTO HasAddress(username, country, location) \
                     VALUES('{}', '{}', '{}')".format(
                session["username"], country, addr
            )
            db.session.execute(query)
            db.session.execute(query2)
            db.session.commit()
            flash("Address saved.")
            return render_template("address.html")
    else:
        return render_template("address.html")


"""
Main Function
"""
if __name__ == "__main__":
    app.run(
        debug=True,
        host='localhost',
        port=5000
    )
