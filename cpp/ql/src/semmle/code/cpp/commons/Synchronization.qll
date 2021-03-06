/**
 * Utilities for analyzing synchronization primitives, such
 * as mutexes and semaphores.
 */
import cpp

/**
 * A type that acts as a mutex.  This class is extended below and and may
 * be extended in `Options.qll`.
 */
abstract class MutexType extends Type {
  /**
   * Holds if `fc` is a call that always locks mutex `arg`
   * of this type.
   */
  abstract predicate mustlockAccess(FunctionCall fc, Expr arg);

  /**
   * Holds if `fc` is a call that tries to lock mutex `arg`
   * of this type, but may return without success.
   */ 
  abstract predicate trylockAccess(FunctionCall fc, Expr arg);

  /**
   * Holds if `fc` is a call that unlocks mutex `arg`
   * of this type.
   */ 
  abstract predicate unlockAccess(FunctionCall fc, Expr arg);

  /**
   * Holds if `fc` is n call that locks or tries to lock mutex
   * `arg` of this type.
   */
  predicate lockAccess(FunctionCall fc, Expr arg) {
    this.mustlockAccess(fc, arg) or
    this.trylockAccess(fc, arg)
  }

  /**
   * Holds if `fc` is a call that locks or tries to lock any
   * mutex of this type.
   */
  FunctionCall getLockAccess() {
    result = getMustlockAccess() or
    result = getTrylockAccess()
  }

  /**
   * Holds if `fc` is a call that always locks any mutex of this type. 
   */
  FunctionCall getMustlockAccess() {
    this.mustlockAccess(result, _)
  }

  /**
   * Holds if `fc` is a call that tries to lock any mutex of this type,
   * by may return without success. 
   */
  FunctionCall getTrylockAccess() {
    this.trylockAccess(result, _)
  }

  /**
   * Holds if `fc` is a call that unlocks any mutex of this type. 
   */
  FunctionCall getUnlockAccess() {
    this.unlockAccess(result, _)
  }

  /**
   * DEPRECATED: use mustlockAccess(fc, arg) instead
   */
  deprecated Function getMustlockFunction() {
    result = getMustlockAccess().getTarget()
  }

  /**
   * DEPRECATED: use trylockAccess(fc, arg) instead
   */
  deprecated Function getTrylockFunction() {
    result = getTrylockAccess().getTarget()
  }

  /**
   * DEPRECATED: use lockAccess(fc, arg) instead
   */
  deprecated Function getLockFunction() {
    result = getLockAccess().getTarget()
  }

  /**
   * DEPRECATED: use unlockAccess(fc, arg) instead
   */
  deprecated Function getUnlockFunction() {
    result = getUnlockAccess().getTarget()
  }
}

/**
 * A function that looks like a lock function.
 */
private Function mustlockCandidate() {
  exists (string name
  | name = result.getName()
  | name = "lock" or
    name.suffix(name.length() - 10) = "mutex_lock")
}

/**
 * A function that looks like a try-lock function.
 */
private Function trylockCandidate() {
  exists (string name
  | name = result.getName()
  | name = "try_lock" or
    name.suffix(name.length() - 13) = "mutex_trylock")
}

/**
 * A function that looks like an unlock function.
 */
private Function unlockCandidate() {
  exists (string name
  | name = result.getName()
  | name = "unlock" or
    name.suffix(name.length() - 12) = "mutex_unlock")
}

/**
 * Gets a type that is a parameter to a function, or it's declaring type
 * (i.e. it's `this`).  If the function is a locking related function,
 * these can be thought of as candidates for the mutex is it locking or
 * unlocking.  It is narrowed down in `DefaultMutexType` by requiring that
 * it must be a class type with both a lock and an unlock function.
 */
private Class lockArgTypeCandidate(Function fcn) {
  result = fcn.getDeclaringType() or
  result = fcn.getAParameter().getType().stripType()
}

/**
 * A class or struct type that has both a lock and an unlock function
 * candidate, and is therefore a mutex.
 * 
 * This excludes types like `std::weak_ptr` which has a lock
 * method, but not an unlock method, and is not a mutex.)
 */
class DefaultMutexType extends MutexType {
  DefaultMutexType() {
    this = lockArgTypeCandidate(mustlockCandidate())
    and
    this = lockArgTypeCandidate(unlockCandidate())
  }

  private predicate lockArgType(FunctionCall fc, Expr arg) {
    exists(int n |
      arg = fc.getArgument(n) and
      fc.getTarget().getParameter(n).getType().stripType() = this
    ) or (
      fc.getTarget().getDeclaringType() = this and
      arg = fc.getQualifier()
    ) or (
      // if we're calling our own method with an implicit `this`,
      // let `arg` be the function call, since we don't really have
      // anything else to use.
      fc.getTarget().getDeclaringType() = this and
      not exists(fc.getQualifier()) and
      arg = fc
    )
  }

  override predicate mustlockAccess(FunctionCall fc, Expr arg) {
    fc.getTarget() = mustlockCandidate() and
    lockArgType(fc, arg)
  }

  override predicate trylockAccess(FunctionCall fc, Expr arg) {
    fc.getTarget() = trylockCandidate() and
    lockArgType(fc, arg)
  }

  override predicate unlockAccess(FunctionCall fc, Expr arg) {
    fc.getTarget() = unlockCandidate() and
    lockArgType(fc, arg)
  }
}

/** Get the mutex argument of a call to lock or unlock. */
private predicate lockArg(Expr arg, MutexType argType, FunctionCall call) {
  argType = arg.getUnderlyingType().stripType() and
  (
    arg = call.getQualifier() or
    arg = call.getAnArgument()
  )
  // note: this seems to arbitrarily care about argument types, rather
  //       than parameter types as elsewhere.  As a result `mustlockCall`,
  //       for example, has slightly different results from
  //       `MutexType.mustlockAccess`.
}

predicate lockCall(Expr arg, FunctionCall call) {
  exists(MutexType t | lockArg(arg, t, call) and call = t.getLockAccess())
}

predicate mustlockCall(Expr arg, FunctionCall call) {
  exists(MutexType t | lockArg(arg, t, call) and call = t.getMustlockAccess())
}

predicate trylockCall(Expr arg, FunctionCall call) {
  exists(MutexType t | lockArg(arg, t, call) and call = t.getTrylockAccess())
}

predicate unlockCall(Expr arg, FunctionCall call) {
  exists(MutexType t | lockArg(arg, t, call) and call = t.getUnlockAccess())
}
