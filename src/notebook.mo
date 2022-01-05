import Array "mo:base/Array";
import Debug "mo:base/Debug";
import Hash "mo:base/Hash";
import HashMap "mo:base/HashMap";
import Iter "mo:base/Iter";
import Nat "mo:base/Nat";
import Principal "mo:base/Principal";
import Time "mo:base/Time";
import Types "./types";

shared({caller}) actor class NoteBook(
  _owner : Principal,
  _name: Text
  ){

  private stable var owner_ : Principal = _owner;
  private stable var name_ : Text = _name;
  private stable var nowId_: Nat = 1000;
  private stable var notes_st: [(Nat, Types.MetaNote)] = [];
  private stable var noteDatas_st: [(Nat, Text)] = [];

  private var notes_ = HashMap.HashMap<Nat, Types.MetaNote>(0, Nat.equal, Hash.hash);
  private var noteDatas_ = HashMap.HashMap<Nat, Text>(0, Nat.equal, Hash.hash);

  // Debug.print(Principal.toText(caller));

  system func preupgrade() {
      notes_st := Iter.toArray(notes_.entries());
      noteDatas_st := Iter.toArray(noteDatas_.entries());
      Debug.print("NoteBook preupgrade")
  };

  system func postupgrade() {
      notes_ := HashMap.fromIter<Nat, Types.MetaNote>(notes_st.vals(), 1, Nat.equal, Hash.hash);
      notes_st := [];
      noteDatas_ := HashMap.fromIter<Nat, Text>(noteDatas_st.vals(), 1, Nat.equal, Hash.hash);
      noteDatas_st := [];
      Debug.print("NoteBook postupgrade")
  };

  private func toLimit(page: Nat, size: Nat, sort: Types.NoteSort) : [Types.MetaNote] {
      var start : Nat = (page - 1) * size;
      if (start < 0) {
        start := 0;
      };
      if (start >= notes_.size()) {
        return [];
      };

      var rets : [Types.MetaNoteSort] = [];
      for((k, v) in notes_.entries()) {
        let st : Types.MetaNoteSort = {
          id = v.id;
          like = v.like;
          createTime = v.createTime;
          topTime = v.topTime;
        };
        rets := Array.append(rets, Array.make(st));
      };
      switch(sort) {
        case(#TimeDesc) {
          rets := Array.sort(rets, Types.compareTimeDesc)
        };
        case(#TimeAsc) {
          rets := Array.sort(rets, Types.compareTimeAsc)
        };
        case(#Like) {
          rets := Array.sort(rets, Types.compareLikeDesc)
        };
      };

      rets := Types.copy(rets, start, size);

      var datas : [Types.MetaNote] = [];
      for( v in rets.vals()) {
        switch(notes_.get(v.id)) {
          case(?note){
            datas := Array.append(datas, Array.make(note));
          };
          case(_){}
        }
      };
      return datas;
  };

  public query({caller}) func getNoteList(page: Nat, sort: Types.NoteSort): async [Types.MetaNote] {
      assert(caller == owner_);
      return toLimit(page, 10, sort);
  };

  public query({caller}) func getNoteData(id: Nat): async Text {
      assert(caller == owner_);
      switch(noteDatas_.get(id)) {
          case(?content) {
              return content;
          };
          case(_){}
      };
      return "";
  };

  // create or update
  public shared({caller}) func createNote(meta: Types.MetaNote, data: Text): async Nat {
      assert(caller == owner_);
      if (meta.id > 0) {
        switch(notes_.get(meta.id)){
          case(?note){
            let newNote : Types.MetaNote = {
              id = meta.id;
              title = meta.title;
              ntype = note.ntype;
              like = meta.like;
              tags = meta.tags;
              topTime = meta.topTime;
              createTime = note.createTime;
              updateTime = Time.now();
              version = note.version + 1;
            };
            notes_.put(meta.id, newNote);
            noteDatas_.put(meta.id, data);
            return meta.id;
          };
          case(_){
            return 0;
          }
        }
      };
      nowId_ := nowId_ + 1;
      let newNote : Types.MetaNote = {
        id = nowId_;
        title = meta.title;
        ntype = meta.ntype;
        like = meta.like;
        tags = meta.tags;
        topTime = 0;
        createTime = Time.now();
        updateTime = Time.now();
        version = 1;
      };
      notes_.put(newNote.id, newNote);
      noteDatas_.put(newNote.id, data);
      return newNote.id;
  };

  public shared({caller}) func deleteNote(id: Nat): async Bool {
      assert(caller == owner_);
      switch(notes_.get(id)){
        case(?note){
          notes_.delete(id);
          noteDatas_.delete(id);
          return true;
        };
        case(_){
          return false;
        }
      }
  };

  public shared({caller}) func toppingNote(id: Nat): async Bool {
      assert(caller == owner_);
      switch(notes_.get(id)){
        case(?note){
            let newNote : Types.MetaNote = {
              id = note.id;
              title = note.title;
              ntype = note.ntype;
              like = note.like;
              tags = note.tags;
              topTime = Time.now();
              createTime = note.createTime;
              updateTime = Time.now();
              version = note.version;
            };
            notes_.put(id, newNote);
            return true;
        };
        case(_){
            return false;
        }
      }
  };
}