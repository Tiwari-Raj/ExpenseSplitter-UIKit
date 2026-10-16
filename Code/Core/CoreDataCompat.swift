//
//  CoreDataCompat.swift
//  ExpenseSplitter
//
//  Depending on how the Core Data model's attributes/relationships were
//  configured (the "Optional" checkbox in Xcode's model editor), the
//  generated NSManagedObject properties can come out as either a plain
//  type (e.g. `String`, `MemberEntity`) or an optional (`String?`,
//  `MemberEntity?`). Both are valid Core Data setups.
//
//  `asOptional` normalizes either shape to an Optional so the rest of the
//  app can always use `?.` / `??` safely, without caring which way a given
//  property was generated. This keeps the app compiling cleanly regardless
//  of the exact "Optional" checkbox state used when the model was created.
//
func asOptional<T>(_ value: T) -> T? { value }
func asOptional<T>(_ value: T?) -> T? { value }
