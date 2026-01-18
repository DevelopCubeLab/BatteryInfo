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
        migrateTableIfNeeded()
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
            maximumCapacity TEXT,
            uuid TEXT,
            maximumQMax INTEGER,
            minimumQMax INTEGER,
            limitVoltage INTEGER,
            originDeviceId TEXT,
            originDeviceName TEXT
        );
        """
        
        if sqlite3_exec(db, createTableQuery, nil, nil, nil) != SQLITE_OK {
            //
        }
    }
    
    private func migrateTableIfNeeded() {
        let expectedColumns = [
            "uuid",
            "maximumQMax",
            "minimumQMax",
            "limitVoltage",
            "originDeviceId",
            "originDeviceName"
        ]

        let checkQuery = "PRAGMA table_info(\(recordTableName));"
        var statement: OpaquePointer?
        var existingColumns: Set<String> = []

        if sqlite3_prepare_v2(db, checkQuery, -1, &statement, nil) == SQLITE_OK {
            while sqlite3_step(statement) == SQLITE_ROW {
                if let columnNameC = sqlite3_column_text(statement, 1) {
                    let columnName = String(cString: columnNameC)
                    existingColumns.insert(columnName)
                }
            }
        }
        sqlite3_finalize(statement)

        for column in expectedColumns where !existingColumns.contains(column) {
            var alterQuery = ""
            if column == "maximumQMax" || column == "minimumQMax" || column == "limitVoltage" {
                alterQuery = "ALTER TABLE \(recordTableName) ADD COLUMN \(column) INTEGER;"
            } else {
                alterQuery = "ALTER TABLE \(recordTableName) ADD COLUMN \(column) TEXT;"
            }
            if sqlite3_exec(db, alterQuery, nil, nil, nil) == SQLITE_OK {
                print("新增列 \(column) 成功")
            } else {
                print("新增列失败: \(column)")
            }
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
                if sqlite3_column_type(statement, 6) != SQLITE_NULL, let rawText = sqlite3_column_text(statement, 6) {
                    maximumCapacity = String(cString: rawText)
                }
                
                var uuid: String?
                if sqlite3_column_type(statement, 7) != SQLITE_NULL, let rawText = sqlite3_column_text(statement, 7) {
                    uuid = String(cString: rawText)
                }
                
                let maximumQMax = sqlite3_column_type(statement, 8) != SQLITE_NULL ? Int(sqlite3_column_int(statement, 8)) : nil
                let minimumQMax = sqlite3_column_type(statement, 9) != SQLITE_NULL ? Int(sqlite3_column_int(statement, 9)) : nil
                let limitVoltage = sqlite3_column_type(statement, 10) != SQLITE_NULL ? Int(sqlite3_column_int(statement, 10)) : nil
                
                var originDeviceId: String?
                if sqlite3_column_type(statement, 11) != SQLITE_NULL, let rawText = sqlite3_column_text(statement, 11) {
                    originDeviceId = String(cString: rawText)
                }
                
                var originDeviceName: String?
                if sqlite3_column_type(statement, 12) != SQLITE_NULL, let rawText = sqlite3_column_text(statement, 12) {
                    originDeviceName = String(cString: rawText)
                }
                
                let record = BatteryDataRecord(id: id,uuid: uuid ?? "", createDate: createDate, recordType: recordType, cycleCount: cycleCount, nominalChargeCapacity: nominalChargeCapacity, designCapacity: designCapacity, maximumCapacity: maximumCapacity, maximumQMax: maximumQMax, minimumQMax: minimumQMax, limitVoltage: limitVoltage, originDeviceId: originDeviceId, originDeviceName: originDeviceName)
                
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
        let record = record
        // 检查 uuid 是否为空字符串，如果是则自动生成
        if record.uuid.isEmpty {
            record.uuid = UUID().uuidString
        }

        let insertQuery = """
        INSERT INTO \(recordTableName) (createDate, recordType, cycleCount, nominalChargeCapacity, designCapacity, maximumCapacity, uuid, maximumQMax, minimumQMax, limitVoltage, originDeviceId, originDeviceName)
        VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?);
        """
        var statement: OpaquePointer?

        if sqlite3_prepare_v2(db, insertQuery, -1, &statement, nil) == SQLITE_OK {

            // 自动生成创建时间
            sqlite3_bind_int(statement, 1, Int32(Date().timeIntervalSince1970))
            // 写入数据
            sqlite3_bind_int(statement, 2, Int32(record.recordType.rawValue))
            sqlite3_bind_int(statement, 3, Int32(record.cycleCount))

            if let nominalChargeCapacity = record.nominalChargeCapacity {
                sqlite3_bind_int(statement, 4, Int32(nominalChargeCapacity))
            } else {
                sqlite3_bind_null(statement, 4)
            }
            if let designCapacity = record.designCapacity {
                sqlite3_bind_int(statement, 5, Int32(designCapacity))
            } else {
                sqlite3_bind_null(statement, 5)
            }

            if let maximumCapacity = record.maximumCapacity {
                sqlite3_bind_text(statement, 6, (maximumCapacity as NSString).utf8String, -1, nil)
            } else {
                sqlite3_bind_null(statement, 6)
            }

            // 用最终的 uuid 绑定到数据库
            sqlite3_bind_text(statement, 7, (record.uuid as NSString).utf8String, -1, nil)

            if let maximumQMax = record.maximumQMax {
                sqlite3_bind_int(statement, 8, Int32(maximumQMax))
            } else {
                sqlite3_bind_null(statement, 8)
            }

            if let minimumQMax = record.minimumQMax {
                sqlite3_bind_int(statement, 9, Int32(minimumQMax))
            } else {
                sqlite3_bind_null(statement, 9)
            }

            if let limitVoltage = record.limitVoltage {
                sqlite3_bind_int(statement, 10, Int32(limitVoltage))
            } else {
                sqlite3_bind_null(statement, 10)
            }

            if let originDeviceId = record.originDeviceId {
                sqlite3_bind_text(statement, 11, (originDeviceId as NSString).utf8String, -1, nil)
            } else {
                sqlite3_bind_null(statement, 11)
            }

            if let originDeviceName = record.originDeviceName {
                sqlite3_bind_text(statement, 12, (originDeviceName as NSString).utf8String, -1, nil)
            } else {
                sqlite3_bind_null(statement, 12)
            }

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
        SELECT id, createDate, recordType, cycleCount, nominalChargeCapacity, designCapacity, maximumCapacity, uuid, maximumQMax, minimumQMax, limitVoltage, originDeviceId, originDeviceName
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
                let uuid = sqlite3_column_type(statement, 7) != SQLITE_NULL ? String(cString: sqlite3_column_text(statement, 7)) : nil
                let maximumQMax = sqlite3_column_type(statement, 8) != SQLITE_NULL ? Int(sqlite3_column_int(statement, 8)) : nil
                let minimumQMax = sqlite3_column_type(statement, 9) != SQLITE_NULL ? Int(sqlite3_column_int(statement, 9)) : nil
                let limitVoltage = sqlite3_column_type(statement, 10) != SQLITE_NULL ? Int(sqlite3_column_int(statement, 10)) : nil
                let originDeviceId = sqlite3_column_type(statement, 11) != SQLITE_NULL ? String(cString: sqlite3_column_text(statement, 11)) : nil
                let originDeviceName = sqlite3_column_type(statement, 12) != SQLITE_NULL ? String(cString: sqlite3_column_text(statement, 12)) : nil

                latestRecord = BatteryDataRecord(id: id, uuid: uuid ?? "", createDate: createDate, recordType: recordType, cycleCount: cycleCount, nominalChargeCapacity: nominalChargeCapacity, designCapacity: designCapacity, maximumCapacity: maximumCapacity, maximumQMax: maximumQMax, minimumQMax: minimumQMax, limitVoltage: limitVoltage, originDeviceId: originDeviceId, originDeviceName: originDeviceName)
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
        SELECT id, createDate, recordType, cycleCount, nominalChargeCapacity, designCapacity, maximumCapacity, uuid, maximumQMax, minimumQMax, limitVoltage, originDeviceId, originDeviceName
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
                let uuid = sqlite3_column_type(statement, 7) != SQLITE_NULL ? String(cString: sqlite3_column_text(statement, 7)) : nil
                let maximumQMax = sqlite3_column_type(statement, 8) != SQLITE_NULL ? Int(sqlite3_column_int(statement, 8)) : nil
                let minimumQMax = sqlite3_column_type(statement, 9) != SQLITE_NULL ? Int(sqlite3_column_int(statement, 9)) : nil
                let limitVoltage = sqlite3_column_type(statement, 10) != SQLITE_NULL ? Int(sqlite3_column_int(statement, 10)) : nil
                let originDeviceId = sqlite3_column_type(statement, 11) != SQLITE_NULL ? String(cString: sqlite3_column_text(statement, 11)) : nil
                let originDeviceName = sqlite3_column_type(statement, 12) != SQLITE_NULL ? String(cString: sqlite3_column_text(statement, 12)) : nil

                record = BatteryDataRecord(id: id, uuid: uuid ?? "", createDate: createDate, recordType: recordType, cycleCount: cycleCount, nominalChargeCapacity: nominalChargeCapacity, designCapacity: designCapacity, maximumCapacity: maximumCapacity, maximumQMax: maximumQMax, minimumQMax: minimumQMax, limitVoltage: limitVoltage, originDeviceId: originDeviceId, originDeviceName: originDeviceName)
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
        
        var csvText = "ID,CreateDate,CycleCount,NominalChargeCapacity,DesignCapacity,MaximumCapacity,UUID,MaximumQMax,MinimumQMax,LimitVoltage,OriginDeviceId,OriginDeviceName\n"
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        
        for record in records {
            let createDateStr = dateFormatter.string(from: Date(timeIntervalSince1970: TimeInterval(record.createDate)))
            let line = "\(record.id),\(createDateStr),\(record.cycleCount),\(record.nominalChargeCapacity ?? 0),\(record.designCapacity ?? 0),\(record.maximumCapacity ?? "N/A"),\(record.uuid),\(record.maximumQMax ?? 0),\(record.minimumQMax ?? 0),\(record.limitVoltage ?? 0),\(record.originDeviceId ?? "N/A"),\(record.originDeviceName ?? "N/A")\n"
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
