import Foundation

// 每一个item的具体数据模型
class InfoItem {
    
    let id: Int              // id
    var text: String         // 文本
    var detailText: String?  // 说明文本
    var sort: Int            // 预留排序标记
    var haveData: Bool       // 是否可用
    
    init(id: Int, text: String) {
        self.id = id
        self.text = text
        self.sort = id
        self.haveData = true
    }
    
    init(id: Int, text: String, haveData: Bool) {
        self.id = id
        self.text = text
        self.sort = id
        self.haveData = haveData
    }
    
    init(id: Int, text: String, sort: Int) {
        self.id = id
        self.text = text
        self.sort = sort
        self.haveData = true
    }
    
    init(id: Int, text: String, detailText: String? = nil, sort: Int) {
        self.id = id
        self.text = text
        self.detailText = detailText
        self.sort = sort
        self.haveData = true
    }
    
    init(id: Int, text: String, detailText: String? = nil, sort: Int, haveData: Bool) {
        self.id = id
        self.text = text
        self.detailText = detailText
        self.sort = sort
        self.haveData = haveData
    }
}
