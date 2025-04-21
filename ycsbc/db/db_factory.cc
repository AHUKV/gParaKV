//
//  basic_db.cc
//  YCSB-C
//
//  Created by Jinglei Ren on 12/17/14.
//  Copyright (c) 2014 Jinglei Ren <jinglei@ren.systems>.
//

#include "../db/db_factory.h"

#include <string>

#include "../db/leveldb_db.h"

using namespace std;

using ycsbc::DB;
using ycsbc::DBFactory;
using ycsbc::LevelDB;

DB* DBFactory::CreateDB(utils::Properties& props) {
  return new LevelDB(props["dbfilename"].c_str(), props["dbfilename"].c_str(),
                     props["configpath"].c_str());
}
