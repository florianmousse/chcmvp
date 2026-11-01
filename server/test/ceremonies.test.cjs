const {test} = require('node:test');
const assert = require('node:assert/strict');
const {validateCeremony, validateBallot, tallyCeremony, youtubeId} = require('../dist/ceremonies');
const body = () => ({title:'Ballon 2026',category:'ballon_or',topSize:5,allowSelfVote:false,
  voterIds:['v1','v2'],nominees:Array.from({length:6},(_,i)=>({uid:`u${i}`,label:`Nomination ${i}`}))});
const event = () => ({...validateCeremony(body()),status:'open',voteCount:0});
test('top 5 validated and countdown scoring, no zero point participant',()=>{
  const e=event();
  const results=tallyCeremony(e,[{uid:'v1',choices:['n1','n2','n3','n4','n5']}]);
  assert.deepEqual(results.map(r=>r.points),[5,4,3,2,1]);
  assert.deepEqual(results.map(r=>r.rank),[1,2,3,4,5]);
  assert(!results.some(r=>r.id==='n6'));
  assert.deepEqual(tallyCeremony(e,[]),[]);
});
test('duplicates, unknown candidates, self votes, inactive status and outsiders rejected',()=>{
  const e=event(), choices=['n1','n2','n3','n4','n5'];
  for(const bad of [[],choices.slice(1),['n1','n1','n3','n4','n5'],['bad',...choices.slice(1)]]) assert.throws(()=>validateBallot(e,'v1',bad));
  assert.throws(()=>validateBallot(e,'outside',choices));
  assert.throws(()=>validateBallot({...e,status:'closed'},'v1',choices));
  assert.throws(()=>validateBallot({...e,voterIds:['u0']},'u0',choices));
  assert.deepEqual(validateBallot({...e,allowSelfVote:true,voterIds:['u0']},'u0',choices),choices);
});

test('different nominations by the same player cannot occupy two ballot positions', () => {
  const e=event(); e.nominees[1].uid=e.nominees[0].uid;
  assert.throws(()=>validateBallot(e,'v1',['n1','n2','n3','n4','n5']), /joueur/);
  assert.deepEqual(validateBallot(e,'v1',['n1','n3','n4','n5','n6']),['n1','n3','n4','n5','n6']);
  const b=body(); b.nominees=b.nominees.map(n=>({...n,uid:'u0'}));
  assert.throws(()=>validateCeremony(b), /joueurs différents/);
});
test('countback resolves equal points; exact ties share rank and win',()=>{
  const e={...event(),topSize:2};
  const tied=tallyCeremony(e,[{uid:'v1',choices:['n1','n2']},{uid:'v2',choices:['n2','n1']}]);
  assert.deepEqual(tied.map(r=>r.rank),[1,1]);
  const countback=tallyCeremony({...e,voterIds:['v1','v2','v3']},[
    {uid:'v1',choices:['n1','n2']},{uid:'v2',choices:['n3','n2']},{uid:'v3',choices:['n4','n5']}]);
  assert(countback.find(r=>r.id==='n1').rank < countback.find(r=>r.id==='n2').rank);
});
test('configuration limits, voter eligibility and strict video URLs',()=>{
  for(const topSize of [0,11,2.5,'5']) assert.throws(()=>validateCeremony({...body(),topSize}));
  assert.throws(()=>validateCeremony({...body(),nominees:body().nominees.slice(0,5),voterIds:['u0']}));
  assert.throws(()=>validateCeremony({...body(),voterIds:[]}));
  assert.equal(youtubeId('https://youtu.be/abcdefghijk'),'abcdefghijk');
  assert.equal(youtubeId('https://www.youtube.com/watch?v=abcdefghijk&t=30'),'abcdefghijk');
  assert.equal(youtubeId('https://youtube.com/shorts/abcdefghijk'),'abcdefghijk');
  for(const url of ['https://youtube.com.evil.test/watch?v=abcdefghijk','javascript:alert(1)','file:///video','<iframe>', 'https://youtu.be/abc']) assert.throws(()=>youtubeId(url));
});
