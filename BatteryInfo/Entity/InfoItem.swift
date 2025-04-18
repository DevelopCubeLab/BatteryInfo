import Foundation

// 每一个item的具体数据模型
class InfoItem {
    
    let id: Int              // id
    var text: String         // 文本
    var detailText: String?  // 说明文本
    var sort: Int            // 预留排序标记
    
    init(id: Int, text: String) {
        self.id = id
        self.text = text
        self.sort = id
    }
    
    init(id: Int, text: String, sort: Int) {
        self.id = id
        self.text = text
        self.sort = sort
    }
    
    init(id: Int, text: String, detailText: String? = nil, sort: Int) {
        self.id = id
        self.text = text
        self.detailText = detailText
        self.sort = sort
    }
}
