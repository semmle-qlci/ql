/**
 * Provides classes representing events and event accessors.
 */

import Member
import Type

/**
 * An event, for example `E` on line 3 in
 *
 * ```
 * class C {
 *   delegate void D();
 *   public event D E;
 * }
 * ```
 */
class Event extends DeclarationWithAccessors, @event {

  override string getName() { events(this,result,_,_,_) }

  override ValueOrRefType getDeclaringType() { events(this,_,result,_,_) }

  override DelegateType getType() { events(this,_,_,getTypeRef(result),_) }

  /** Gets an `add` or `remove` accessor of this event, if any. */
  EventAccessor getAnEventAccessor() { result.getDeclaration() = this }

  /** Gets the `add` accessor of this event, if any. */
  AddEventAccessor getAddEventAccessor() { result = getAnEventAccessor() }

  /** Gets the `remove` accessor of this event, if any. */
  RemoveEventAccessor getRemoveEventAccessor() { result = getAnEventAccessor() }

  /**
   * Holds if this event can be used like a field within its declaring type
   * (this information is available for source events only).
   */
  predicate isFieldLike() {
    this.fromSource() and
    not this.isExtern() and
    not this.isAbstract() and
    not this.getAnEventAccessor().hasBody()
  }

  override Event getSourceDeclaration() { events(this,_,_,_,result) }

  override Event getOverridee() {
    result = DeclarationWithAccessors.super.getOverridee()
  }

  override Event getAnOverrider() {
    result = DeclarationWithAccessors.super.getAnOverrider()
  }

  override Event getImplementee() {
    result = DeclarationWithAccessors.super.getImplementee()
  }

  override Event getAnImplementor() {
    result = DeclarationWithAccessors.super.getAnImplementor()
  }

  override Event getAnUltimateImplementee() {
    result = DeclarationWithAccessors.super.getAnUltimateImplementee()
  }

  override Event getAnUltimateImplementor() {
    result = DeclarationWithAccessors.super.getAnUltimateImplementor()
  }

  override Location getALocation() { event_location(this,result) }
}

/**
 * An event accessor, for example `add` on line 4 or `remove`
 * on line 5 in
 *
 * ```
 * class C {
 *   delegate void D();
 *   public event D E {
 *     add { }
 *     remove { }
 *   }
 * }
 * ```
 */
class EventAccessor extends Accessor, @event_accessor {
  override Type getReturnType() {
    exists(this) and // needed to avoid compiler warning
    result instanceof VoidType
  }

  /** Gets the assembly name of this event accessor. */
  string getAssemblyName() { event_accessors(this,_,result,_,_) }

  override EventAccessor getSourceDeclaration() { event_accessors(this,_,_,_,result) }

  override Event getDeclaration() { event_accessors(this,_,_,result,_) }

  override Location getALocation() { event_accessor_location(this,result) }
}

/**
 * An add event accessor, for example `add` on line 4 in
 *
 * ```
 * class C {
 *   delegate void D();
 *   public event D E {
 *     add { }
 *     remove { }
 *   }
 * }
 * ```
 */
class AddEventAccessor extends EventAccessor, @add_event_accessor {
  override string getName() { result = "add" + "_" + getDeclaration().getName() }
}

/**
 * A remove event accessor, for example `remove` on line 5 in
 *
 * ```
 * class C {
 *   delegate void D();
 *   public event D E {
 *     add { }
 *     remove { }
 *   }
 * }
 * ```
 */
class RemoveEventAccessor extends EventAccessor, @remove_event_accessor {
  override  string getName() { result = "remove" + "_" + getDeclaration().getName() }
}
