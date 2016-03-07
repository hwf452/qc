enum Result<T, E: ErrorType> {
  case Success(T)
  case Failure(E)
  
  func map<U>(@noescape f: T -> U) -> Result<U, E> {
    return flatMap { .Success(f($0)) }
  }
  
  func flatMap<U>(@noescape f: T -> Result<U, E>) -> Result<U, E> {
    switch self {
    case let .Success(x): return f(x)
    case let .Failure(e): return Result<U, E>.Failure(e)
    }
  }
}
