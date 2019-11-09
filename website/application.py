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
@app.route("/logout")
def logout():
    session.clear()
    flash("Logged out.")
    return redirect("/")

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

@app.route("/profile")
def profile():
    user = session["username"]
    query = "SELECT * FROM Owns WHERE username='{}'".format(user)
    result = db.session.execute(query).fetchall()
    projects = []
    for i in result:
        projects.append(int(str(i[1])))
    data = []
    for i in projects:
        query = "SELECT * FROM Project WHERE projectId={}".format(i)
        result = db.session.execute(query).fetchone()
        data.append(result)

    return render_template("profile.html", data=data)

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
            "product_desc":    form["product-description"],
            "category":        form["category"]
        }

        query = "SELECT 1 FROM Project WHERE name='{}'".format(data["project_name"])
        project_exists = db.session.execute(query).fetchone()
        if project_exists:
            flash("That project name is already taken.")
            return render_template("new_project.html")
        else:
            now = datetime.date.today()
            data["creation_date"] = str(now)
            query = "SELECT COUNT(*) FROM Project"
            num = db.session.execute(query).fetchone()
            project_id = int(num[0])
            data["project_id"] = project_id + 1
            query = "INSERT INTO Project(projectId, name, expiration_date, goal) VALUES ({}, '{}', '{}', '{}')" \
                .format(
                    data["project_id"],
                    data["project_name"],
                    data["expiration_date"],
                    data["goal"]
                )
            query2 = "INSERT INTO Product(productId, projectId, productDescription, productPrice) VALUES('{}', {}, '{}', {})" \
                .format(
                    data["product_name"],
                    data["project_id"],
                    data["product_desc"],
                    data["product_price"]
                )
            query3 = "INSERT INTO Owns(username, projectId) VALUES ('{}', {})" \
                .format(
                    session["username"],
                    data["project_id"]
                )
            query4 = "INSERT INTO Contains(projectId, name) VALUES({}, '{}')" \
                .format(
                    data["project_id"],
                    data["category"]
                )
            
            db.session.execute(query)
            db.session.execute(query2)
            db.session.execute(query3)
            db.session.commit()
            return redirect(url_for("render_project_page", data=data))
    else:
        return render_template("new_project.html")

@app.route("/get_project", methods=["GET", "POST"])
def get_project():
    if request.method == "POST":
        form = request.form
        pname = form["project-name"]

        query = "SELECT * FROM Project WHERE name='{}'".format(pname)
        ret = db.session.execute(query).fetchone()
        query = "SELECT * FROM Product WHERE projectId={}".format(ret[0])
        ret2 = db.session.execute(query).fetchone()
        query = "SELECT name FROM Contains WHERE projectId={}".format(ret[0])
        ret3 = db.session.execute(query).fetchone()

        total = 0
        if "username" in session:
            query = "SELECT amount FROM Transaction WHERE projectId={} AND username='{}'".format(ret[0], session["username"])
            ret4 = db.session.execute(query).fetchall()
            for i in ret4:
                total += float(i[0])

        query = "SELECT amount FROM Transaction WHERE projectId={}".format(ret[0])
        ret5 = db.session.execute(query).fetchall()
        total2 = 0
        for i in ret5:
            total2 += float(i[0])

        data = {
            "project_name":    str(ret[1]),
            "creation_date":   str(ret[2]),
            "expiration_date": str(ret[3]),
            "product_name":    str(ret2[0]),
            "product_price":   str(ret2[3]),
            "product_desc":    str(ret2[2]),
            "category":        str(ret3[0]),
            "user_funded":     str(total),
            "funded":          str(total2)
        }

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

@app.route("/fund", methods=["GET", "POST"])
def fund():
    if request.method == "POST":
        form = request.form
        num = form["fund-amount"]
        project_name = form["project-name"]
        project_id = db.session.execute(f"SELECT projectId FROM Project WHERE name='{project_name}'").fetchone()[0]
        product_id = form["product-name"]
        if (int(num) < 0):
            return redirect(request.referrer)
        if (int(num) > 10**5):
            flash("The specified amount is too much.")
            return redirect(request.referrer)
        if not has_credit_card():
            flash("You do not have a credit card available to support this.")
            return redirect(request.referrer)
        query = "INSERT INTO Transaction(username, projectId, productId, amount) \
            VALUES ('{}', {}, '{}', {})".format(
            session["username"],
            project_id,
            product_id,
            num
        )
        db.session.execute(query)
        db.session.commit()
        flash(f"Funded ${num} to {project_name}")
        return redirect("/projects")
    return redirect(request.referrer)

def has_credit_card():
    if not session["username"]:
        return False
    return db.session.execute(f"SELECT 1 FROM HasCreditCard WHERE \
            username='{session['username']}'").fetchone()

"""
Main Function
"""
if __name__ == "__main__":
    app.run(
        debug=True,
        host='localhost',
        port=5000
    )
