#!/usr/bin/python
# coding=utf-8

import time
import json
import requests

import config_center
import db_helper 

#不指定则针对所有namespace
#namespace = "'qce/lb'"
namespace = ""

#地域
region = "use"

#目标ctsdb信息
ctsdb_addr = ""
ctsdb_user = "root"
ctsdb_passwd = ""

def get_metrics():
    url = "http://%s/_metrics" % ctsdb_addr
    try:
        print "curl -XGET -H 'Content-Type:application/json' ", url 
        r = requests.get(url, headers={'Content-Type': 'application/json'},
                        auth=(ctsdb_user, ctsdb_passwd))
        results = r.json()
        #print json.dumps(results)
        if "result" in results:
            return results["result"]["metrics"]
    except requests.exceptions.RequestException as e:
        print "get metrics error:" + e.message

def put_default_doc(metric):
    url = "http://%s/%s/_doc/_default_doc_id" % (ctsdb_addr, metric)
    try:
        print "curl -X POST -H 'Content-Type:application/json' ", url, "-d '{\"test\":1}'"
        r = requests.post(url, data='{"test":1}', headers={"Content-Type": "application/json"},
                            auth=(ctsdb_user, ctsdb_passwd))
        results = r.json()
        print json.dumps(results)
    except requests.exceptions.RequestException as e:
        print "put default doc fail, metric:" + metric + " error:" + e.message

def get_tables(db_config):
    sql = "select concat('0_barad_',c.viewName,'-',a.outputPeriod) as indexName from cAssociationMiningRule as a, " \
          "cDimensionGroup as b, cDimensionView as c where a.outputPeriod in(5,10,60,300) and " \
          "b.dimGroupId=a.outputDimGroupId and c.dimensionGroup=b.dimensionGroup and c.namespace = b.namespace " \
          "group by c.viewName,a.outputPeriod;"
    if len(namespace) > 0:
        sql = "select concat('0_barad_',c.viewName,'-',a.outputPeriod) as indexName from cAssociationMiningRule as a, " \
          "cDimensionGroup as b, cDimensionView as c where a.outputPeriod in(5,10,60,300) and " \
          "b.dimGroupId=a.outputDimGroupId and c.dimensionGroup=b.dimensionGroup and b.namespace in(%s) and c.namespace = b.namespace " \
          "group by c.viewName,a.outputPeriod;" % namespace
    print sql
    with db_helper.open_cursor(db_config['host'], db_config['port'], db_config['default'], db_config['user'], db_config['passwd']) as cursor:
        rows = db_helper.getAll(cursor, sql)
        results = [row['indexName'] for row in rows]
    return results

if __name__ == '__main__':
    ccdb_config_str = config_center.loadConfig(region, 'db.baradConfig')
    if len(ccdb_config_str) > 0:
        db_config = json.loads(ccdb_config_str)
        tables = get_tables(db_config)
        metrics = get_metrics()
        for table in tables:
            if table in metrics:
                print "pre-create index for metric %s" % table 
                put_default_doc(table)
            else:
                print "%s not created" % table
