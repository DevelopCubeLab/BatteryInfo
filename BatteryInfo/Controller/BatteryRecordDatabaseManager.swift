import Foundation
import SQLite3

class BatteryRecordDatabaseManager {
    
    static let shared = BatteryRecordDatabaseManager()
    
    private let dbName = "BatteryData.sqlite"
    private let recordTableName = "BatteryDataRecords"
    private var db: OpaquePointer?
    
    private init() {
        openDatabase()
        createTable()
    }
    
    /// 打开数据库
    private func openDatabase() {
        let fileURL = FileManager.default
            .urls(for: .documentDirectory, in: .userDomainMask)
            .first!
            .appendingPathComponent(dbName)
        
        if sqlite3_open(fileURL.path, &db) != SQLITE_OK {
            //
        }
    }
    
    /// 创建表
    private func createTable() {
        let createTableQuery = """
        CREATE TABLE IF NOT EXISTS \(recordTableName) (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            createDate INTEGER NOT NULL,
            recordType INTEGER NOT NULL,
            cycleCount INTEGER NOT NULL,
            nominalChargeCapacity INTEGER,
            designCapacity INTEGER,
            maximumCapacity TEXT
        );
        """
        
        if sqlite3_exec(db, createTableQuery, nil, nil, nil) != SQLITE_OK {
            //
        }
    }
    
    /// 查询所有记录
    func fetchAllRecords() -> [BatteryDataRecord] {
        let fetchQuery = "SELECT * FROM \(recordTableName) ORDER BY createDate DESC;"
        
        var statement: OpaquePointer?
        var records: [BatteryDataRecord] = []
        
        if sqlite3_prepare_v2(db, fetchQuery, -1, &statement, nil) == SQLITE_OK {
            
            while sqlite3_step(statement) == SQLITE_ROW {
                let id = Int(sqlite3_column_int(statement, 0))
                let createDate = Int(sqlite3_column_int(statement, 1))
                let recordType = BatteryDataRecord.BatteryDataRecordType(rawValue: Int(sqlite3_column_int(statement, 2))) ?? .Automatic
                let cycleCount = Int(sqlite3_column_int(statement, 3))
                
                let nominalChargeCapacity = sqlite3_column_type(statement, 4) != SQLITE_NULL ? Int(sqlite3_column_int(statement, 4)) : nil
                let designCapacity = sqlite3_column_type(statement, 5) != SQLITE_NULL ? Int(sqlite3_column_int(statement, 5)) : nil
                
                var maximumCapacity: String?
                if let rawText = sqlite3_column_text(statement, 6) {
                    maximumCapacity = String(cString: rawText)
                }
                
                let record = BatteryDataRecord(id: id, createDate: createDate, recordType: recordType, cycleCount: cycleCount, nominalChargeCapacity: nominalChargeCapacity, designCapacity: designCapacity, maximumCapacity: maximumCapacity)
                
                records.append(record)
            }
            
        } else {
            print("查询失败: \(String(cString: sqlite3_errmsg(db)))")
        }
        
        sqlite3_finalize(statement)
        return records
    }
    
    func getRecordCount() -> Int {
        let countQuery = "SELECT COUNT(*) FROM \(recordTableName);"
        var statement: OpaquePointer?
        var count: Int = 0
        
        if sqlite3_prepare_v2(db, countQuery, -1, &statement, nil) == SQLITE_OK {
            if sqlite3_step(statement) == SQLITE_ROW {
                count = Int(sqlite3_column_int(statement, 0))
            }
        } else {
            print("查询记录数失败: \(String(cString: sqlite3_errmsg(db)))")
        }
        
        sqlite3_finalize(statement)
        return count
    }

    
    func insertRecord(_ record: BatteryDataRecord) -> Bool {
        let insertQuery = """
        INSERT INTO \(recordTableName) (createDate, recordType, cycleCount, nominalChargeCapacity, designCapacity, maximumCapacity)
        VALUES (?, ?, ?, ?, ?, ?);
        """
        
        var statement: OpaquePointer?
        
        if sqlite3_prepare_v2(db, insertQuery, -1, &statement, nil) == SQLITE_OK {
            
            sqlite3_bind_int(statement, 1, Int32(Date().timeIntervalSince1970))
            sqlite3_bind_int(statement, 2, Int32(record.recordType.rawValue))
            sqlite3_bind_int(statement, 3, Int32(record.cycleCount))
            sqlite3_bind_int(statement, 4, Int32(record.nominalChargeCapacity ?? 0))
            sqlite3_bind_int(statement, 5, Int32(record.designCapacity ?? 0))
            
//            if let maximumCapacity = record.maximumCapacity {
//                sqlite3_bind_text(statement, 6, (maximumCapacity as NSString).utf8String, -1, nil)
//            } else {
//                sqlite3_bind_null(statement, 6)
//            }
            
            if sqlite3_step(statement) == SQLITE_DONE {
                sqlite3_finalize(statement)
                return true
            } else {
                sqlite3_finalize(statement)
                return false
            }
            
        } else {
            sqlite3_finalize(statement)
            return false
        }
        
    }
    
    /// 删除一条记录
    func deleteRecord(byID id: Int) -> Bool {
        let deleteQuery = "DELETE FROM \(recordTableName) WHERE id = ?;"
        
        var statement: OpaquePointer?
        
        if sqlite3_prepare_v2(db, deleteQuery, -1, &statement, nil) == SQLITE_OK {
            sqlite3_bind_int(statement, 1, Int32(id))
            
            if sqlite3_step(statement) == SQLITE_DONE {
                sqlite3_finalize(statement)
                return true
            } else {
                sqlite3_finalize(statement)
                return false
            }
        } else {
            sqlite3_finalize(statement)
            return false
        }
        
    }
    
    func getLatestRecord() -> BatteryDataRecord? {
        let query = """
        SELECT id, createDate, recordType, cycleCount, nominalChargeCapacity, designCapacity, maximumCapacity
        FROM \(recordTableName)
        ORDER BY createDate DESC
        LIMIT 1;
        """
        
        var statement: OpaquePointer?
        var latestRecord: BatteryDataRecord? = nil
        
        if sqlite3_prepare_v2(db, query, -1, &statement, nil) == SQLITE_OK {
            if sqlite3_step(statement) == SQLITE_ROW {
                let id = Int(sqlite3_column_int(statement, 0))
                let createDate = Int(sqlite3_column_int(statement, 1))
                let recordType = BatteryDataRecord.BatteryDataRecordType(rawValue: Int(sqlite3_column_int(statement, 2))) ?? .Automatic
                let cycleCount = Int(sqlite3_column_int(statement, 3))
                
                let nominalChargeCapacity = sqlite3_column_type(statement, 4) != SQLITE_NULL ? Int(sqlite3_column_int(statement, 4)) : nil
                let designCapacity = sqlite3_column_type(statement, 5) != SQLITE_NULL ? Int(sqlite3_column_int(statement, 5)) : nil
                let maximumCapacity = sqlite3_column_type(statement, 6) != SQLITE_NULL ? String(cString: sqlite3_column_text(statement, 6)) : nil

                latestRecord = BatteryDataRecord(id: id, createDate: createDate, recordType: recordType, cycleCount: cycleCount, nominalChargeCapacity: nominalChargeCapacity, designCapacity: designCapacity, maximumCapacity: maximumCapacity)
            }
        } else {
            print("没有查询到: \(String(cString: sqlite3_errmsg(db)))")
        }
        
        sqlite3_finalize(statement)
        return latestRecord
    }
    
    /// 查询指定循环次数的最新记录
    func getRecord(byCycleCount cycleCount: Int) -> BatteryDataRecord? {
        let query = """
        SELECT id, createDate, recordType, cycleCount, nominalChargeCapacity, designCapacity, maximumCapacity
        FROM \(recordTableName)
        WHERE cycleCount = ?
        ORDER BY createDate DESC
        LIMIT 1;
        """

        var statement: OpaquePointer?
        var record: BatteryDataRecord? = nil

        if sqlite3_prepare_v2(db, query, -1, &statement, nil) == SQLITE_OK {
            sqlite3_bind_int(statement, 1, Int32(cycleCount))

            if sqlite3_step(statement) == SQLITE_ROW {
                let id = Int(sqlite3_column_int(statement, 0))
                let createDate = Int(sqlite3_column_int(statement, 1))
                let recordType = BatteryDataRecord.BatteryDataRecordType(rawValue: Int(sqlite3_column_int(statement, 2))) ?? .Automatic
                let cycleCount = Int(sqlite3_column_int(statement, 3))

                let nominalChargeCapacity = sqlite3_column_type(statement, 4) != SQLITE_NULL ? Int(sqlite3_column_int(statement, 4)) : nil
                let designCapacity = sqlite3_column_type(statement, 5) != SQLITE_NULL ? Int(sqlite3_column_int(statement, 5)) : nil
                let maximumCapacity = sqlite3_column_type(statement, 6) != SQLITE_NULL ? String(cString: sqlite3_column_text(statement, 6)) : nil

                record = BatteryDataRecord(id: id, createDate: createDate, recordType: recordType, cycleCount: cycleCount, nominalChargeCapacity: nominalChargeCapacity, designCapacity: designCapacity, maximumCapacity: maximumCapacity)
            }
        } else {
            print("查询指定循环次数的记录失败: \(String(cString: sqlite3_errmsg(db)))")
        }

        sqlite3_finalize(statement)
        return record
    }
    
    // 导出全部记录为CSV
    func exportToCSV() -> URL? {
        let records = fetchAllRecords()
        guard !records.isEmpty else {
            NSLog("No records found to export.")
            return nil
        }
        
        let fileName = NSLocalizedString("BatteryDataRecordsCSVName", comment: "BatteryDataRecords").appending(".csv")
        let fileURL = FileManager.default.temporaryDirectory.appendingPathComponent(fileName)
        
        var csvText = "ID,CreateDate,CycleCount,NominalChargeCapacity,DesignCapacity,MaximumCapacity\n"
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        
        for record in records {
            let createDateStr = dateFormatter.string(from: Date(timeIntervalSince1970: TimeInterval(record.createDate)))
            let line = "\(record.id),\(createDateStr),\(record.cycleCount),\(record.nominalChargeCapacity ?? 0),\(record.designCapacity ?? 0),\(record.maximumCapacity ?? "N/A")\n"
            csvText.append(line)
        }
        
        do {
            try csvText.write(to: fileURL, atomically: true, encoding: .utf8)
            NSLog("CSV file created at: \(fileURL.path)")
            return fileURL
        } catch {
            NSLog("Failed to write CSV file: \(error.localizedDescription)")
            return nil
        }
    }
    
    // 删除全部数据
    func deleteAllRecords() {
        let deleteQuery = "DELETE FROM \(recordTableName);"

        if sqlite3_exec(db, deleteQuery, nil, nil, nil) == SQLITE_OK {
            print("All records deleted successfully.")
        }
    }
    
}
