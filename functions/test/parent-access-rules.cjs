const assert = require('node:assert/strict');
const host = process.env.FIRESTORE_EMULATOR_HOST;
if (host !== '127.0.0.1:8193') throw Error('Use the isolated local parent emulator');
const project = 'demo-learnable-parent';
const database = `projects/${project}/databases/(default)`;
const base = `http://${host}/v1/${database}/documents`;
const fields = data => Object.fromEntries(Object.entries(data).map(([k,v]) => [k,{stringValue:v}]));
function token(uid, name, admin=false) {
  const encode = data => Buffer.from(JSON.stringify(data)).toString('base64url');
  const now = Math.floor(Date.now()/1000);
  return `${encode({alg:'none',typ:'JWT'})}.${encode({sub:uid,user_id:uid,aud:project,iss:`https://securetoken.google.com/${project}`,iat:now,exp:now+3600,name,admin,firebase:{sign_in_provider:'password'}})}.`;
}
async function request(path, method, body, auth) {
  const response=await fetch(base+path,{method,headers:{'Content-Type':'application/json',...(auth?{Authorization:`Bearer ${auth}`}:{})},...(body?{body:JSON.stringify(body)}:{})});
  return {status:response.status,body:await response.text()};
}
(async()=>{
  const data = {
    'users/P0001':{role:'parent',authUid:'parent-uid',status:'Active',childrenId:'S0001'},
    'users/P0002':{role:'parent',authUid:'other-parent-uid',status:'Active',childrenId:'S0002'},
    'users/S0001':{role:'student',authUid:'child-uid',firstName:'Child',grade:'Grade 3'},
    'users/S0002':{role:'student',authUid:'other-child-uid'},
    'users/T0001':{role:'teacher',authUid:'teacher-uid'},
    'activityScores/child':{userId:'S0001',activityName:'MathGame1'},
    'activityScores/other':{userId:'S0002',activityName:'EnglishGame1'},
  };
  const seed=await request(':commit','POST',{writes:Object.entries(data).map(([path,value])=>({update:{name:`${database}/documents/${path}`,fields:fields(value)}}))},'owner');
  assert.equal(seed.status,200,seed.body);
  let count=0;
  async function check(name,path,method,body,auth,allowed) {
    const result=await request(path,method,body,auth);assert.equal(result.status,allowed?200:403,`${name}: ${result.body}`);console.log('PASS '+name);count++;
  }
  const parent=token('parent-uid','P0001'), student=token('child-uid','S0001');
  const query=id=>({structuredQuery:{from:[{collectionId:'activityScores'}],where:{fieldFilter:{field:{fieldPath:'userId'},op:'EQUAL',value:{stringValue:id}}}}});
  await check('parent reads linked child profile and grades','/users/S0001','GET',null,parent,true);
  await check('parent reads linked child activity query',':runQuery','POST',query('S0001'),parent,true);
  await check('parent cannot read another child activity query',':runQuery','POST',query('S0002'),parent,false);
  await check('forged parent ID does not grant access',':runQuery','POST',query('S0001'),token('other-parent-uid','P0001'),false);
  await check('parent cannot modify child grades','/users/S0001','PATCH',{fields:fields({grade:'Grade 9'})},parent,false);
  await check('parent cannot change its child link','/users/P0001','PATCH',{fields:fields({childrenId:'S0002'})},parent,false);
  await check('parent cannot submit child scores','/activityScores/parent-write','PATCH',{fields:fields({userId:'S0001'})},parent,false);
  await check('changing display name cannot enable parent score writes','/activityScores/spoof-write','PATCH',{fields:fields({userId:'S0001'})},token('parent-uid','S0001'),false);
  await check('parent cannot delete child scores','/activityScores/child','DELETE',null,parent,false);
  await check('student can still submit own scores','/activityScores/student-write','PATCH',{fields:fields({userId:'S0001'})},student,true);
  await check('student cannot submit another student scores','/activityScores/other-write','PATCH',{fields:fields({userId:'S0002'})},student,false);
  await check('teacher read access preserved',':runQuery','POST',query('S0001'),token('teacher-uid','T0001'),true);
  await check('admin read access preserved',':runQuery','POST',query('S0001'),token('admin-uid','admin',true),true);
  await check('signed-out score writes denied','/activityScores/anonymous-write','PATCH',{fields:fields({userId:'S0001'})},null,false);
  await request('/users/P0001','PATCH',{fields:fields({...data['users/P0001'],status:'Inactive'})},'owner');
  await check('inactive parent loses activity access',':runQuery','POST',query('S0001'),parent,false);
  console.log(`${count} parent access checks passed. No live data used.`);
})().catch(error=>{console.error(error);process.exitCode=1;});
