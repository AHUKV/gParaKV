//
//  ycsb-c.cc
//  YCSB-C
// -
//  Created by Jinglei Ren on 12/19/14.
//  Copyright (c) 2014 Jinglei Ren <jinglei@ren.systems>.
//

#include <chrono>
#include <cstring>
#include <filesystem>
#include <future>
#include <iostream>
#include <string>
#include <thread>

#include "core/client.h"
#include "core/core_workload.h"
#include "core/timer.h"
#include "db/db_factory.h"
#include "db/my_stats.h"

using namespace std;

void UsageMessage();

bool StrStartWith(const char *str, const char *pre);

std::string ParseCommandLine(int argc, const char *argv[],
                             utils::Properties &props);

int DelegateClient(ycsbc::DB *db, ycsbc::CoreWorkload *wl, size_t num_ops,
                   bool is_loading) {
  time_t now = time(nullptr);
  fprintf(stderr, "Time: %s", ctime(&now));  // ctime() adds newline
  db->Init();
  ycsbc::Client client(*db, *wl);
  int oks = 0;
  int ops_stage = 100;

  for (size_t i = 0; i < num_ops; ++i) {
    if (is_loading) {
      oks += client.DoInsert();
    } else {
      oks += client.DoTransaction();
    }

    if (oks >= ops_stage) {
      if (ops_stage < 1000)
        ops_stage += 100;
      else if (ops_stage < 5000)
        ops_stage += 500;
      else if (ops_stage < 10000)
        ops_stage += 1000;
      else if (ops_stage < 50000)
        ops_stage += 5000;
      else if (ops_stage < 100000)
        ops_stage += 10000;
      else if (ops_stage < 500000)
        ops_stage += 50000;
      else
        ops_stage += 100000;
      fprintf(stderr, "... finished %d ops\n", oks);
      fflush(stderr);
    }
  }

  db->Close();
  return oks;
}

int Run(utils::Properties props, const std::string &filename) {
  ycsbc::DB *db = ycsbc::DBFactory::CreateDB(props);

  if (!db) {
    cout << "Unknown database name " << props["dbname"] << endl;
    exit(0);
  }

  ycsbc::CoreWorkload wl;
  wl.Init(props);

  // Loads data
  cerr << "--------------------Loading--------------------" << endl;

  size_t total_ops = stoll(props[ycsbc::CoreWorkload::RECORD_COUNT_PROPERTY]);

  utils::Timer<double> timer_load;
  timer_load.Start();

  size_t sum = DelegateClient(db, &wl, total_ops, true);

  double duration_load = timer_load.End();

  std::this_thread::sleep_for(std::chrono::seconds(1));

  cerr << "\n----------------------Loading-----------------------" << endl;
  cerr << "Loading records : " << sum << endl;
  cerr << "Loading duration: " << duration_load << " sec" << endl;
  cerr << "Loading throughput (KTPS): "
       << static_cast<double>(total_ops) / duration_load / 1000 << endl;
  cerr << "----------------------------------------------------" << endl;

  std::this_thread::sleep_for(std::chrono::seconds(5));

  cerr << endl;

  // Performs transactions
  cerr << "--------------------Transaction--------------------" << endl;

  size_t num_ops = stoll(props[ycsbc::CoreWorkload::OPERATION_COUNT_PROPERTY]);

  utils::Timer<double> timer;
  timer.Start();

  size_t sum_transaction = DelegateClient(db, &wl, num_ops, false);
  db->PrintMyStats();

  double duration = timer.End();

  std::this_thread::sleep_for(std::chrono::seconds(2));
  cerr << endl;

  cerr << "DB name: " << props["dbname"] << endl;
  cerr << "Workload filename: " << filename << endl;

  cerr << "----------------------Loading-----------------------" << endl;
  cerr << "Loading records : " << sum << endl;
  cerr << "Loading duration: " << duration_load << " sec" << endl;
  cerr << "Loading throughput (KTPS): "
       << static_cast<double>(total_ops) / duration_load / 1000 << endl;
  cerr << "----------------------------------------------------" << endl;

  cerr << "--------------------Transaction---------------------" << endl;
  cerr << "Read proportion: "
       << std::stod(props[ycsbc::CoreWorkload::READ_PROPORTION_PROPERTY])
       << endl;
  cerr << "Transactions records : " << sum_transaction << endl;
  cerr << "Transactions duration: " << duration << " sec" << endl;
  cerr << "Transaction throughput (KTPS): "
       << static_cast<double>(num_ops) / duration / 1000 << endl;
  cerr << "----------------------------------------------------" << endl;

  return 0;
}

std::string ParseCommandLine(int argc, const char *argv[],
                             utils::Properties &props) {
  std::string filename;
  int argindex = 1;
  while (argindex < argc && StrStartWith(argv[argindex], "-")) {
    if (strcmp(argv[argindex], "-db") == 0) {
      argindex++;
      if (argindex >= argc) {
        UsageMessage();
        exit(0);
      }
      props.SetProperty("dbname", argv[argindex]);
      argindex++;
    } else if (strcmp(argv[argindex], "-host") == 0) {
      argindex++;
      if (argindex >= argc) {
        UsageMessage();
        exit(0);
      }
      props.SetProperty("host", argv[argindex]);
      argindex++;
    } else if (strcmp(argv[argindex], "-port") == 0) {
      argindex++;
      if (argindex >= argc) {
        UsageMessage();
        exit(0);
      }
      props.SetProperty("port", argv[argindex]);
      argindex++;
    } else if (strcmp(argv[argindex], "-slaves") == 0) {
      argindex++;
      if (argindex >= argc) {
        UsageMessage();
        exit(0);
      }
      props.SetProperty("slaves", argv[argindex]);
      argindex++;
    } else if (strcmp(argv[argindex], "-filename") == 0) {
      argindex++;
      if (argindex >= argc) {
        UsageMessage();
        exit(0);
      }

      props.SetProperty("dbfilename", argv[argindex]);
      argindex++;
    } else if (strcmp(argv[argindex], "-configpath") == 0) {
      argindex++;
      if (argindex >= argc) {
        UsageMessage();
        exit(0);
      }
      props.SetProperty("configpath", argv[argindex]);
      argindex++;
    } else if (strcmp(argv[argindex], "-P") == 0) {
      argindex++;
      if (argindex >= argc) {
        UsageMessage();
        exit(0);
      }

      filename.assign(argv[argindex]);
      ifstream input(filename);
      try {
        props.Load(input);
      } catch (const string &message) {
        cout << message << endl;
        exit(0);
      }
      input.close();
      argindex++;
    } else {
      cout << "Unknown option '" << argv[argindex] << "'" << endl;
      exit(0);
    }
  }

  std::error_code ec;
  for (auto &entry :
       filesystem::directory_iterator(props.GetProperty("dbfilename"), ec)) {
    filesystem::remove_all(entry, ec);
  }

  for (auto &entry :
       filesystem::directory_iterator(props.GetProperty("vlog"), ec)) {
    filesystem::remove_all(entry, ec);
  }

  if (argindex == 1 || argindex != argc) {
    UsageMessage();
    exit(0);
  }

  return filename;
}

void UsageMessage() {
  std::cout << "example: \n"
               "-filename\n"
               "/media/d306/8bb53358-409c-470b-8697-1ea61b3e8f2a\n"
               "-db\n"
               "rocksdb\n"
               "-configpath\n"
               "0\n"
               "-P\n"
               "/home/d306/My/GPURocksDB-V3/workloads/100/workloadc.spec"
            << std::endl;
}

inline bool StrStartWith(const char *str, const char *pre) {
  return strncmp(str, pre, strlen(pre)) == 0;
}

int main(const int argc, const char *argv[]) {
  utils::Properties props;
  string filename = ParseCommandLine(argc, argv, props);

  leveldb::my_stats.original_value_size =
      std::stoul(props.GetProperty("fieldlength"));
  uint32_t encoded_original_value_size;
  if (leveldb::my_stats.original_value_size < 1 << 7) {
    encoded_original_value_size = 1;
  } else if (leveldb::my_stats.original_value_size < 1 << 14) {
    encoded_original_value_size = 2;
  } else {
    encoded_original_value_size = 3;
  }
  leveldb::my_stats.var_key_value_size = 1 + 16 + 1 +
                                         leveldb::my_stats.original_value_size +
                                         encoded_original_value_size;

  size_t num = std::stoul(props.GetProperty("recordcount"));
  uint32_t vlog_size_tmp = 64 << 20;
  uint32_t log_item_size = 12 + leveldb::my_stats.var_key_value_size;  // 1056
  uint32_t max_num_log_item =
      ((vlog_size_tmp / log_item_size + 100) / 100) * 100;
  leveldb::my_stats.max_num_log_item = max_num_log_item;
  leveldb::my_stats.max_num_log = num / max_num_log_item + 1;
  leveldb::my_stats.max_vlog_size =
      max_num_log_item * (12 + leveldb::my_stats.var_key_value_size);

  leveldb::my_stats.clean_threshold = std::ceil((double)max_num_log_item * 0.25);

  Run(props, filename);

  return 0;
}
