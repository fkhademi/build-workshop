#!/usr/bin/env python3

import urllib3
import json
import boto3
urllib3.disable_warnings(urllib3.exceptions.InsecureRequestWarning)
from datetime import datetime
from bottle import route, run, post, request, static_file, error
import string
import random

def get_next_pod_id(id, name, email, company, start_time, code, dynamodb=None):
    # Get the next Pod ID of a Build class.  Max pods are 50
    if not dynamodb:
        dynamodb = boto3.resource('dynamodb', region_name='eu-central-1', verify=False)
    # Query table for Build ID
    table = dynamodb.Table('pod_counter')
    response = table.get_item(
       Key={
            'id': id
        }
    )
    print(response)
    try:
    # try to parse the object    
        pod_num = response['Item']['pod_num']
    except:
        # Build date not found or pod num cannot be parsed
        print("Error parsing the pod number")
        return(0)
    else:
        # Increment Pod Counter
        pod_num=pod_num+1
        padded_pod_num = str(pod_num).zfill(3)
        add_pod(id, pod_num, code)
        # Set User ID
        user_id = "%s-%s" %(id, padded_pod_num)
        # Add User to Pod History
        add_user(id, user_id, name, email, company, start_time)
        print("Added user %s to the pod history") %user_id
        return(pod_num)
 

def get_code(id, dynamodb=None):
    # Get the access code for Build ID
    if not dynamodb:
        dynamodb = boto3.resource('dynamodb', region_name='eu-central-1', verify=False)
    # Query table for Build ID
    table = dynamodb.Table('pod_counter')
    response = table.get_item(
       Key={
            'id': id
        }
    )
    try:
    # try to parse the object    
        code = response['Item']['code']
    except:
        # If code not found, print an error
        return '''Error Access Code Not Found'''
    else:
        print("Found Code %s") %code
        return(code)

def add_pod(id, pod_num, code, dynamodb=None):
    # Insert a new record in DynamoDB
    if not dynamodb:
        dynamodb = boto3.resource('dynamodb', region_name='eu-central-1', verify=False)

    table = dynamodb.Table('pod_counter')
    response = table.put_item(
       Item={
            'id': id,
            'pod_num': pod_num,
            'code': code
        }
    )

def add_user(id, user_id, name, email, company, start_time, dynamodb=None):
    # Insert a new record in DynamoDB
    if not dynamodb:
        dynamodb = boto3.resource('dynamodb', region_name='eu-central-1', verify=False)

    table = dynamodb.Table('pod_history')
    response = table.put_item(
       Item={
            'user_id': user_id,
            'id': id,
            'full_name': name,
            'company': company,
            'email': email,
            'start_time': start_time
        }
    )

# Access Code Generator
def id_generator(size=6, chars=string.ascii_uppercase + string.digits):
    return ''.join(random.choice(chars) for _ in range(size))

# Route for creating a new Build Session
@route('/new')
def server_static(filepath="new.html"):
    return static_file(filepath, root='./public/')

@post('/newclass')
def process():
    max_pods = request.forms.get('max_pods')
    now = datetime.now()
    id = "%s-%s-%s" % (now.year, '{:02d}'.format(now.month), '{:02d}'.format(now.day))
    # POD Start time # %m/%d/%Y, %H:%M:%S
    now = now.strftime("%Y-%m-%dT%H:%M:%S")
    # Get a new Access Code
    code = id_generator()
    # Insert a new record in DynamoDB
    try:
        add_pod(id, 0, code)
    except:
        return '''<html>
        <link href="https://stackpath.bootstrapcdn.com/bootstrap/4.3.1/css/bootstrap.min.css" rel="stylesheet" id="bootstrap-css">

        <center>
        <div class="jumbotron jumbotron-fluid">
        <div class="container" style="width:200px;">
        <img src="/static/logo.png" class="img-fluid">
        </div>
        </div>
        <div class="alert alert-danger" role="alert">Unable to update DB!</div>'''
    else:
        return '''<html>
        <link href="https://stackpath.bootstrapcdn.com/bootstrap/4.3.1/css/bootstrap.min.css" rel="stylesheet" id="bootstrap-css">

        <center>
        <div class="jumbotron jumbotron-fluid">
        <div class="container" style="width:200px;">
        <img src="/static/logo.png" class="img-fluid">
        </div>
        </div>
        <div class="alert alert-primary" role="alert">New Access Code: %s</b></div>
        ''' %(code)




@route('/')
def server_static(filepath="index.html"):
    return static_file(filepath, root='./public/')

@route('/static/<filepath:path>')
def server_static(filepath):
    return static_file(filepath, root='./public/')

@post('/doform')
def process():
    # Get the form vars
    max_num_pods = 46
    domain = "avxlab.cc"
    name = request.forms.get('name')
    email = request.forms.get('email')
    company = request.forms.get('company')
    code = request.forms.get('code')

    #Get the current date and time
    now = datetime.now()
    id = "%s-%s-%s" % (now.year, '{:02d}'.format(now.month), '{:02d}'.format(now.day))

    build_code = get_code(id)

    if code == build_code:
        now = now.strftime("%Y-%m-%dT%H:%M:%S")
        # Get the next POD ID
        pod_id = get_next_pod_id(id, name, email, company, now, code)
        
        if pod_id <= max_num_pods:
            # print a page to display pod info
            return '''<html>
            <link href="https://stackpath.bootstrapcdn.com/bootstrap/4.3.1/css/bootstrap.min.css" rel="stylesheet" id="bootstrap-css">

            <center>
            <div class="jumbotron jumbotron-fluid">
            <div class="container" style="width:200px;">
            <img src="/static/logo.png" class="img-fluid">
            </div>
            </div>
            <div class="alert alert-primary" role="alert">You've been assigned <b>Pod %s</b></div>
            <br>
            <div class="row">
            <div class="col-sm-4">
                <div class="card">
                <div class="card-body">
                    <h5 class="card-title">Remote Access Server</h5>
                    <p class="card-text">u: pod%s</p>
                    <a target="_blank" rel="noopener noreferrer" href="https://client.pod%s.%s" class="btn btn-primary">Open Server</a>
                </div>
                </div>
            </div>
            <div class="col-sm-4">
                <div class="card">
                <div class="card-body">
                    <h5 class="card-title">Aviatrix Controller</h5>
                    <p class="card-text">u: admin</p>
                    <a target="_blank" rel="noopener noreferrer" href="https://ctrl.pod%s.%s" class="btn btn-primary">Open Controller</a>
                </div>
                </div>
            </div>
            <div class="col-sm-4">
                <div class="card">
                <div class="card-body">
                    <h5 class="card-title">Aviatrix Co-Pilot</h5>
                    <p class="card-text">u: admin</p>
                    <a target="_blank" rel="noopener noreferrer" href="https://cplt.pod%s.%s" class="btn btn-primary">Open Co-Pilot</a>
                </div>
                </div>
            </div>
            </div>
            <div class="row">
            <div class="col-sm-12">
                <div class="card">
                <div class="card-body">
                    <h5 class="card-title">Lab Guide</h5>
                    <p class="card-text">Download the lab guide here</p>
                    <a target="_blank" rel="noopener noreferrer" href="https://avx-build.s3.eu-central-1.amazonaws.com/Aviatrix-Build-Lab-Guide-1.0.pdf" class="btn btn-primary">Open Lab Guide</a>
                </div>
                </div>
            </div>
            </div>''' %(pod_id, pod_id, pod_id, domain, pod_id, domain, pod_id, domain)
            
        else:
            # print a page to say that there are no more pods left
            return '''<html>
            <link href="https://stackpath.bootstrapcdn.com/bootstrap/4.3.1/css/bootstrap.min.css" rel="stylesheet" id="bootstrap-css">

            <center>
            <div class="jumbotron jumbotron-fluid">
            <div class="container" style="width:400px;">
            <img src="/static/logo.png" class="img-fluid">
            </div>
            </div>
            <div class="alert alert-danger" role="alert">No more pods left</div>'''
    else:
        # print a page to say that there are no more pods left
        return '''<html>
        <link href="https://stackpath.bootstrapcdn.com/bootstrap/4.3.1/css/bootstrap.min.css" rel="stylesheet" id="bootstrap-css">

        <center>
        <div class="jumbotron jumbotron-fluid">
        <div class="container" style="width:400px;">
        <img src="/static/logo.png" class="img-fluid">
        </div>
        </div>
        <div class="alert alert-danger" role="alert">Wrong Access Code! Please try again</div>'''

@error(404)
def error404(error):
    return '404 - the requested page could not be found'

run(host='0.0.0.0', reloader=True, port=8080, debug=True)

