# 📚 PZXSideMenuController

A lightweight and flexible side menu controller for iOS, written in Swift.  
一个轻量且灵活的 iOS 侧边栏控制器，使用 Swift 编写。

---

## ✨ Features | 特性

- Easy to integrate, easy to use  
  易集成，易使用
- Customizable menu width, animation, and background  
  可自定义菜单宽度、动画和背景
- Gesture support for swipe to open/close  
  支持手势滑动开关
- Compatible with UIKit and Storyboard  
  兼容 UIKit 和 Storyboard

---

## 🛠 Installation | 安装

直接将 `PZXSideMenuController` 文件夹放入项目。

---

## 🚀 Usage | 使用示例

```swift
import PZXSideMenuController

let homeVC = ViewController()
let leftVC = LeftViewController()

// 1. 初始化和设置
let sideMenu = PZXSideMenuController(sideMenu: leftVC, main: homeVC)
let sideMenuNavVC = UINavigationController(rootViewController: sideMenu)
window?.rootViewController = sideMenuNavVC

// 2. 外部代码控制侧边栏
PZXSideMenuController.openSideMenu()           // 打开侧边栏
PZXSideMenuController.closeSideMenu()          // 关闭侧边栏
PZXSideMenuController.openSideMenu(animated: false)  // 无动画打开

// 3. 检查状态
if let isOpen = PZXSideMenuController.isMenuOpen() {
    print("侧边栏状态: \(isOpen ? "打开" : "关闭")")
}
```
## 📄 Requirements | 环境要求

- iOS 11.0+
- Swift 5+

---

## 📌 License | 许可证

MIT License. See [LICENSE](./LICENSE) for details.  
MIT 协议，详情见 [LICENSE](./LICENSE)。

---

## 👨‍💻 Author | 作者

**PZXSideMenuController** is maintained by [KpengS].  
如有问题或建议，欢迎 Issue 和 PR！
