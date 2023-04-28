#!/usr/bin/python
# coding=utf-8

import getopt
import json
import sys
import time

import requests

import config_center
import db_helper

#不指定则针对所有namespace
#namespace = "'qce/lb'"
namespace = ""

#地域
region = "use"

#源ctsdb信息
src_es_hosts = "9.12.182.73:9200"
src_es_user = "root"
src_es_passwd = "monitor@tencent"

#目标stsdb信息
dst_es_hosts = "9.31.48.116:10011"
dst_es_user = "root"
dst_es_passwd = "monitor@tencent"

def get_metrics():
    url = "http://%s/_metrics" % dst_es_hosts
    try:
        print "curl -XGET -H 'Content-Type:application/json' ", url 
        r = requests.get(url, headers={'Content-Type': 'application/json'},
                          auth=(dst_es_user, dst_es_passwd))
        results = r.json()
        print json.dumps(results)
        if "result" in results:
            return results["result"]["metrics"]
    except requests.exceptions.RequestException as err:
        print "get metrics error:" + err.message


def set_metric(index_name, metric_body):
    url = "http://%s/_metric/%s" % (dst_es_hosts, index_name)
    try:
        print "curl -X POST -H 'Content-Type:application/json' ", url, "-d '", json.dumps(metric_body), "'"
        r = requests.post(url, data=json.dumps(metric_body), headers={'Content-Type': 'application/json'},
                          auth=(dst_es_user, dst_es_passwd))
        results = r.json()
        print json.dumps(results)
    except requests.exceptions.RequestException as err:
        print "set metric fail,index name: " + index_name + " error:" + err.message


def set_metric_options(index_name, metric_body):
    url = "http://%s/_metric/%s/update" % (dst_es_hosts, index_name)
    body = metric_body['options']
    current_body = get_current_metric(index_name)
    if 'options' in current_body:
        if 'rolling_period' in current_body['options']:
            if 'rolling_period' in body:
                if current_body['options']['rolling_period'] == body['rolling_period'] & body['rolling_period'] != -1:
                    body['rolling_period'] += 1
    try:
        print "curl -X POST -H 'Content-Type:application/json' ", url, "-d '", json.dumps(body), "'"
        r = requests.post(url, data=json.dumps(metric_body), headers={'Content-Type': 'application/json'},
                          auth=(dst_es_user, dst_es_passwd))
        results = r.json()
        print json.dumps(results)
    except requests.exceptions.RequestException as err:
        print "set metric options fail,index name: " + index_name + " error:" + err.message


def get_metric(index_name):
    url = "http://%s/_metric/%s" % (src_es_hosts, index_name)
    try:
        r = requests.get(url, auth=(src_es_user, src_es_passwd))
        results = r.json()
        print json.dumps(results)
        if "result" in results:
            return results["result"][index_name]
        else:
            return ""
    except requests.exceptions.RequestException as err:
        print "get metric: " + index_name + " error:" + err.message
        return ""


def get_current_metric(index_name):
    url = "http://%s/_metric/%s" % (dst_es_hosts, index_name)
    try:
        r = requests.get(url, auth=(dst_es_user, dst_es_passwd))
        results = r.json()
        print json.dumps(results)
        if "result" in results:
            return results["result"][index_name]
        else:
            return ""
    except requests.exceptions.RequestException as err:
        print "get curret metric: " + index_name + " error:" + err.message
        return ""


def get_tables(db_config):
    sql = "select concat('0_barad_',c.viewName,'-',a.outputPeriod) as indexName from cAssociationMiningRule as a, " \
          "cDimensionGroup as b, cDimensionView as c where a.outputPeriod in(5,10,60,300) and " \
          "b.dimGroupId=a.outputDimGroupId and c.dimensionGroup=b.dimensionGroup and c.namespace = b.namespace " \
          "group by c.viewName,a.outputPeriod; "
    if len(namespace) > 0:
        sql = "select concat('0_barad_',c.viewName,'-',a.outputPeriod) as indexName from cAssociationMiningRule as a, " \
          "cDimensionGroup as b, cDimensionView as c where a.outputPeriod in(5,10,60,300) and " \
          "b.dimGroupId=a.outputDimGroupId and c.dimensionGroup=b.dimensionGroup and b.namespace in (%s) and c.namespace = b.namespace " \
          "group by c.viewName,a.outputPeriod; " % namespace
    print sql
    with db_helper.open_cursor(db_config['host'], db_config['port'], db_config['default'],
                               db_config['user'],
                               db_config['passwd']) as cursor:
        results = db_helper.getAll(cursor, sql)
    return results


def get_meta_tables(db_config):
    sql = "select concat('0_barad_',viewName) as vName from cDimensionView"
    if len(namespace) > 0:
        sql = "select concat('0_barad_',viewName) as vName from cDimensionView where namespace in (%s)" % namespace
    print sql
    with db_helper.open_cursor(db_config['host'], db_config['port'], db_config['default'],
                               db_config['user'],
                               db_config['passwd']) as cursor:
        results = db_helper.getAll(cursor, sql)
    return results


if __name__ == '__main__':
    ccdb_config_str = config_center.loadConfig(region, 'db.baradConfig')
    metrics = get_metrics()
    if len(ccdb_config_str) > 0:
        db_config = json.loads(ccdb_config_str)
        tables = get_tables(db_config)
        if tables is not None and len(tables) > 0:
            for table in tables:
                metric_body = get_metric(table['indexName'])
                if len(metric_body) > 0:
                    if table['indexName'] not in metrics:
                        set_metric(table['indexName'], metric_body)
                        print "create metric:", table['indexName']
        meta_tables = get_meta_tables(db_config)
        if meta_tables is not None and len(meta_tables) > 0:
            for table in meta_tables:
                metric_body = get_metric(table['vName'])
                if len(metric_body) > 0:
                    if table['vName'] not in metrics:
                        set_metric(table['vName'], metric_body)
                        print "create meta metric:", table['vName']
