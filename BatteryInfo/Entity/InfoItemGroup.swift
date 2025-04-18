import Foundation

class InfoItemGroup {
    
    let id: Int                           // 组id
    var titleText: String?                // 顶部文本
    private(set) var items: [InfoItem]    // 这一组的内容
    var footerText: String?               // 底部文本
    
    init(id: Int) {
        self.id = id
        self.items = []
    }
    
    init(id: Int, items: [InfoItem]) {
        self.id = id
        self.items = items
    }
    
    init(id: Int, titleText: String, items: [InfoItem]) {
        self.id = id
        self.titleText = titleText
        self.items = items
    }
    
    init(id: Int, items: [InfoItem], footerText: String) {
        self.id = id
        self.items = items
        self.footerText = footerText
    }
    
    init(id: Int, titleText: String, items: [InfoItem], footerText: String) {
        self.id = id
        self.titleText = titleText
        self.items = items
        self.footerText = footerText
    }
    
    // 添加单个条目
    func addItem(_ item: InfoItem) {
        self.items.append(item)
    }

    // 添加多个条目
    func addItems(_ newItems: [InfoItem]) {
        self.items.append(contentsOf: newItems)
    }

    // 清空所有条目
    func clearItems() {
        self.items.removeAll()
    }
    
}
