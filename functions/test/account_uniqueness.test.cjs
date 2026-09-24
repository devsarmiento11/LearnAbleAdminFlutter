const {test}=require('node:test');const assert=require('node:assert/strict');
const {identity,saveUniqueProfile}=require('../account_uniqueness');
const parent={role:'parent',firstName:' Jane ',middleName:'',lastName:'DOE',email:' Jane@Example.com '};
test('normalizes identity, permits different people sharing email',()=>{
 assert.equal(identity(parent),identity({...parent,firstName:'jane',lastName:'doe',email:'jane@example.com'}));
 assert.notEqual(identity(parent),identity({...parent,firstName:'John'}));
});
test('student identity includes birthday and ignores school year',()=>{
 const p={...parent,role:'student',birthday:'2015-04-01T00:00:00.000'};
 assert.equal(identity(p),identity({...p,schoolYear:'2028-2029'}));
 assert.notEqual(identity(p),identity({...p,birthday:'2015-04-02'}));
});
test('transaction rejects existing person with a different ID',async()=>{
 let writes=0;const reference={};const query={};const db={collection:()=>({where:()=>query}),runTransaction:fn=>fn({get:async ref=>ref===reference?{exists:false}:{docs:[{data:()=>parent}]},create:()=>writes++})};
 await assert.rejects(saveUniqueProfile({db,reference,data:parent,HttpsError:Error}),/already-exists/);assert.equal(writes,0);
});
test('transaction creates a distinct teacher',async()=>{
 let writes=0;const reference={};const db={collection:()=>({where:()=>({})}),runTransaction:fn=>fn({get:async ref=>ref===reference?{exists:false}:{docs:[]},create:()=>writes++})};
 await saveUniqueProfile({db,reference,data:{...parent,role:'teacher'},HttpsError:Error});assert.equal(writes,1);
});
