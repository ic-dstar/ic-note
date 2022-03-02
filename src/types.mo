/**
* module: types.mo
* Copyright  : 2021 Dstar Team
*/
import Hash "mo:base/Hash";
import Int "mo:base/Int";
import Nat "mo:base/Nat";
import Nat64 "mo:base/Nat64";
import Order "mo:base/Order";
import Prim "mo:prim";
import Time "mo:base/Time";

module {

    public type NoteType = {
      #Note;
      #BoxItem;
    };

    public type NoteSort = {
      #TimeDesc;
      #TimeAsc;
      #Like;
    };

    public type MetaNote = {
      id: Nat;
      title: Text;
      ntype: NoteType; //
      tags: Text; // 1,2,3
      like: Bool;
      createTime: Int;
      updateTime: Int;
      topTime: Int; //topTime, zero is not top
      version: Nat;
    };

    public type MetaNoteSort = {
      id: Nat;
      like: Bool;
      createTime: Int;
      topTime: Int;
    };

    public type NoteStat = {
      noteCount: Nat;
      boxCount: Nat;
    };

    // smaller -> bigger
    public func compareTimeAsc(a : MetaNoteSort, b : MetaNoteSort) : Order.Order {
        if (a.topTime > 0 and b.topTime > 0) {
          return Int.compare(a.createTime, b.createTime);
        } else if (a.topTime > 0 and b.topTime <= 0) {
          return #less;
        } else if (b.topTime > 0 and a.topTime <= 0) {
          return #greater;
        };
        return Int.compare(a.createTime, b.createTime);
    };

    // bigger -> smaller
    public func compareTimeDesc(a : MetaNoteSort, b : MetaNoteSort) : Order.Order {
        if (a.topTime > 0 and b.topTime > 0) {
          return Int.compare(b.createTime, a.createTime);
        } else if (a.topTime > 0 and b.topTime <= 0) {
          return #less;
        } else if (b.topTime > 0 and a.topTime <= 0) {
          return #greater;
        };
        return Int.compare(b.createTime, a.createTime);
    };

    public func compareLikeDesc(a : MetaNoteSort, b : MetaNoteSort) : Order.Order {
        if (a.topTime > 0 and b.topTime > 0) {
          return compareLike(a, b);
        } else if (a.topTime > 0 and b.topTime <= 0) {
          return #less;
        } else if (b.topTime > 0 and a.topTime <= 0) {
          return #greater;
        };
        return compareLike(a, b);
    };

    func compareLike(a: MetaNoteSort, b : MetaNoteSort): Order.Order {
        if (b.like and not a.like) {
          return #greater;
        } else if (a.like and not b.like) {
          return #less;
        } else {
          return Int.compare(a.createTime, b.createTime);
        };
    };

    public func copy<A>(xs: [A], start: Nat, length: Nat) : [A] {
        if (start > xs.size()) return [];

        let size : Nat = xs.size() - start;
        var items = length;

        if (size < length)
            items := size;

        Prim.Array_tabulate<A>(items, func (i : Nat) : A {
            xs[i+start];
        });
    };
}