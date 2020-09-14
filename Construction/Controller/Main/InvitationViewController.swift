import UIKit
import SVProgressHUD

class InvitationViewController: BarHidableViewController {
    @IBOutlet weak var tblProjects: UITableView!
    var dataSource: DataSource<Project>?
    
    func acceptInvitation(project: Project) {
        if let user = Manager.shared.user {
            user.invited.remove(project)
            project.users.insert(user)
            user.projects.insert(project)
        }
        
        if let title = project.title {
            self.alert(message: "Congratulations!, You are now a member of \(title)")
        }
        else {
            self.alert(message: "Congratulations!, You accepted the invitation.")
        }
    }
    
    func createProject(name: String, description: String) {
        let project: Project = Project()
        project.title = name
        project.content = description
        if let user = Manager.shared.user {
            project.managerId = user.id
            project.users.insert(user)
            
            SVProgressHUD.show(withStatus: "Creating...")
            
            project.save { (ref, err) in
                SVProgressHUD.dismiss()
                user.projects.insert(project)
            }
        }
    }
    
    func setupDataSource() {
        let options: Options = Options()
        options.limit = 10
        //        options.predicate = NSPredicate(format: "age == 21")
        options.sortDescirptors = [NSSortDescriptor(key: "createdAt", ascending: false)]
        if let user = Manager.shared.user {
            self.dataSource = DataSource(reference: user.invited.ref, block: { (changes) in
                guard let tableView: UITableView = self.tblProjects else {return}
                
                switch changes {
                case .initial:
                    tableView.reloadData()
                case .update(let deletions, let insertions, let modifications):
                    tableView.beginUpdates()
                    tableView.insertRows(at: insertions.map { IndexPath(row: $0, section: 0) }, with: .automatic)
                    tableView.deleteRows(at: deletions.map { IndexPath(row: $0, section: 0) }, with: .automatic)
                    tableView.reloadRows(at: modifications.map { IndexPath(row: $0, section: 0) }, with: .automatic)
                    tableView.endUpdates()
                case .error(let error):
                    print(error)
                }
            })
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.setupDataSource()
    }
}

extension InvitationViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.dataSource?.count ?? 0
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "PROJECT_CELL", for: indexPath) as! ProjectTableViewCell
        configure(cell, atIndexPath: indexPath)
        return cell
    }
    
    func configure(_ cell: ProjectTableViewCell, atIndexPath indexPath: IndexPath) {
        cell.disposer = self.dataSource?.observeObject(at: indexPath.item, block: { (project) in
            guard let project = project else {return}
            cell.reset(with: project)
            cell.setNeedsLayout()
        })
    }
    
    private func tableView(_ tableView: UITableView, didEndDisplaying cell: ProjectTableViewCell, forRowAt indexPath: IndexPath) {
        //self.dataSource?.removeObserver(at: indexPath.item)
        cell.disposer?.dispose()
    }
    
    func tableView(_ tableView: UITableView, canPerformAction action: Selector, forRowAt indexPath: IndexPath, withSender sender: Any?) -> Bool {
        return true
    }
    
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            self.dataSource?.removeObject(at: indexPath.item, block: { (key, error) in
                if let error: Error = error {
                    print(error)
                }
            })
        }
    }
}

extension InvitationViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 50;
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if let source = self.dataSource {
            if indexPath.row < source.count {
                let project = source.objects[indexPath.row]
                self.alert(title: "Hi", message: "Are you gonna accept this invitation?", options: "Yes", "No") { (index) in
                    if index == 0 {
                        self.acceptInvitation(project: project)
                    }
                }
            }
        }
    }
}

