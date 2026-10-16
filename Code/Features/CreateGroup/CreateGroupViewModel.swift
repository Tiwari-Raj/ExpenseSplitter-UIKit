//
//  CreateGroupViewModel.swift
//  ExpenseSplitter
//

import CoreData

final class CreateGroupViewModel {

    private let context: NSManagedObjectContext

    /// Member names entered so far, in order.
    private(set) var memberNames: [String] = []

    init(context: NSManagedObjectContext) {
        self.context = context
    }

    var numberOfMembers: Int {
        memberNames.count
    }

    func memberName(at index: Int) -> String {
        memberNames[index]
    }

    enum ValidationError: LocalizedError {
        case emptyName
        case duplicateName
        case tooFewMembers

        var errorDescription: String? {
            switch self {
            case .emptyName:
                return "Please enter a member name."
            case .duplicateName:
                return "That member has already been added."
            case .tooFewMembers:
                return "Add at least one member before adding another."
            }
        }
    }

    @discardableResult
    func addMember(named rawName: String) -> Result<Int, ValidationError> {
        let name = rawName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !name.isEmpty else { return .failure(.emptyName) }
        guard !memberNames.contains(where: { $0.caseInsensitiveCompare(name) == .orderedSame }) else {
            return .failure(.duplicateName)
        }
        memberNames.append(name)
        return .success(memberNames.count - 1)
    }

    func removeMember(at index: Int) {
        memberNames.remove(at: index)
    }

    enum CreateGroupError: LocalizedError {
        case emptyGroupName
        case noMembers

        var errorDescription: String? {
            switch self {
            case .emptyGroupName:
                return "Please give your group a name."
            case .noMembers:
                return "Add at least one member to the group."
            }
        }
    }

    /// Creates the GroupEntity + its MemberEntities and saves the context.
    @discardableResult
    func createGroup(named rawGroupName: String) -> Result<GroupEntity, CreateGroupError> {
        let groupName = rawGroupName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !groupName.isEmpty else { return .failure(.emptyGroupName) }
        guard !memberNames.isEmpty else { return .failure(.noMembers) }

        let group = GroupEntity(context: context)
        group.id = UUID()
        group.name = groupName
        group.dateCreated = Date()

        for name in memberNames {
            let member = MemberEntity(context: context)
            member.id = UUID()
            member.name = name
            member.group = group
        }

        do {
            try context.save()
            return .success(group)
        } catch {
            assertionFailure("Failed to save new group: \(error)")
            context.rollback()
            return .failure(.emptyGroupName)
        }
    }
}
