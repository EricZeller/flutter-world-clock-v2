'use strict';
const MANIFEST = 'flutter-app-manifest';
const TEMP = 'flutter-temp-cache';
const CACHE_NAME = 'flutter-app-cache';

const RESOURCES = {"assets/AssetManifest.bin": "913378497f53ebc3444f5e663294b26c",
"assets/AssetManifest.bin.json": "5cc4920c21d3265846837e73b3e1f14e",
"assets/AssetManifest.json": "e92529aea27d605c40751721c70b2645",
"assets/assets/flags/ad.png": "692682a7278d6b018186b9cc3abb16f7",
"assets/assets/flags/ae.png": "2bbe2e62f5716b03f99b364e97d52354",
"assets/assets/flags/af.png": "e137cd4cb256e4c9a465383e1f06c14b",
"assets/assets/flags/ag.png": "1dd7e0d9774ea66e8a71d0675dfcd61b",
"assets/assets/flags/ai.png": "5f99d8146a3ae2819001ae9ec40920c1",
"assets/assets/flags/al.png": "5ed86603786c1b775c3bf2508f92ed2c",
"assets/assets/flags/am.png": "82f7a14d94b7ceddeab5bd6e57dd11e1",
"assets/assets/flags/ao.png": "8d5df3b0fdcd5b91b07ff488b4be4132",
"assets/assets/flags/aq.png": "e4b2d9566c61edcbfee3ad2e75b52e34",
"assets/assets/flags/ar.png": "e9d0f58593921ea932b1222983f632c6",
"assets/assets/flags/as.png": "98f5f53274a782db753a8cafd79b9ca9",
"assets/assets/flags/at.png": "b917dd3ccba73e3033de3dfad4ae5d73",
"assets/assets/flags/au.png": "f9b1378ebc3d7497c9124be2ce9d141a",
"assets/assets/flags/aw.png": "bb5662016bcc1f8af8dc6a2844951175",
"assets/assets/flags/ax.png": "632147bfcc0a4d0e76afd606674b6657",
"assets/assets/flags/az.png": "a62c95707ac879773f81b7f5b9be3938",
"assets/assets/flags/ba.png": "856993d949f3ae1d2386a71c66ee6345",
"assets/assets/flags/bb.png": "605aa9ab9c300211c827ec456c6ef98a",
"assets/assets/flags/bd.png": "74a6501c959fb259f9154c8ce3bd46e3",
"assets/assets/flags/be.png": "bcaece6fa6d857a9c13aafa4a8513d49",
"assets/assets/flags/bf.png": "fc8e334c6f51b1ea9a9e500c657eb5ec",
"assets/assets/flags/bg.png": "ea4c8813ffd93ecdc82126ab5121a16e",
"assets/assets/flags/bh.png": "44a58be8e7262c472c8277621b1adbcb",
"assets/assets/flags/bi.png": "4bc69a0a57355f5c76cc064b8d8da15a",
"assets/assets/flags/bj.png": "d44d7c6b5ec5533441c475984d36c4d9",
"assets/assets/flags/bl.png": "a99b38626e9299fb2eda789997e56928",
"assets/assets/flags/bm.png": "4cc956904355f5330381338a1f99f237",
"assets/assets/flags/bn.png": "88357f221018902dfe2c2ba99e7be742",
"assets/assets/flags/bo.png": "78c1a772df6fe19c76532bbfe3d2b9c5",
"assets/assets/flags/bq.png": "12abe062bec199bb6d88a153781ec44d",
"assets/assets/flags/br.png": "42894c8b13394ba90f4a566d86403bce",
"assets/assets/flags/bs.png": "f405ba378af6e49a58d591de3dd3c157",
"assets/assets/flags/bt.png": "322b8f5220446595d197f09f6c6a2429",
"assets/assets/flags/bv.png": "3afab54f2d4f9c42b9532c2c95806b5f",
"assets/assets/flags/bw.png": "c646736a00e510bc2837626559b80ffa",
"assets/assets/flags/by.png": "2e13d4a7e4f177e3fbdc32bc973e84cd",
"assets/assets/flags/bz.png": "b7fa081c23d835e5ae74b02e2965fd26",
"assets/assets/flags/ca.png": "cc00eb304b28c4fb9b0f8a22e88d79c3",
"assets/assets/flags/cc.png": "320ca8e3304ef6a907d1efd72c4b214c",
"assets/assets/flags/cd.png": "0321bea99f53b5b0c5e7a7916049b33a",
"assets/assets/flags/cf.png": "76c8d2c918e1da023965aacf86d76d5f",
"assets/assets/flags/cg.png": "1138d60b6f7aba50abe5a2b42c470ccf",
"assets/assets/flags/ch.png": "fa62de254012b0e0d930f952d91d4218",
"assets/assets/flags/ci.png": "95003b2e2f99684579c89040eac6d913",
"assets/assets/flags/ck.png": "a7c952efea2316d31108ee8f69c5379f",
"assets/assets/flags/cl.png": "adce6f7efd4509de82df447736316202",
"assets/assets/flags/cm.png": "c0ebbce60011ff96429d6050f71a1b06",
"assets/assets/flags/cn.png": "430041b64975b5f88d93651558145990",
"assets/assets/flags/co.png": "4eb68e3bfb1c0b0f8c6107d2ac96fe7e",
"assets/assets/flags/cr.png": "412d6eb9cc44c0e8fc297b7d0b64dacb",
"assets/assets/flags/cu.png": "2f25aadfe4cb134b95b898fa6c3942f8",
"assets/assets/flags/cv.png": "8c7e38e067d2e5325b8085489f75596d",
"assets/assets/flags/cw.png": "b55b02c24cb12cb17e6b122433461e5a",
"assets/assets/flags/cx.png": "c08163585de1f531a590ea758aecb377",
"assets/assets/flags/cy.png": "76bcb6836d49226784cd9917abd8b971",
"assets/assets/flags/cz.png": "92457a57114cd5946903b9adec4670ab",
"assets/assets/flags/de.png": "b4643304aa865b430f83028fea4275b3",
"assets/assets/flags/dj.png": "d3116abf3887fd9d46e1e602cba04036",
"assets/assets/flags/dk.png": "dedd552befccd774bfa5265b103f0b72",
"assets/assets/flags/dm.png": "7c238ec9ce7372e9f248b533ac88186a",
"assets/assets/flags/do.png": "8d661528bd3ae920aa23a8eee55453d3",
"assets/assets/flags/dz.png": "179662edd8108dd37830d87d14867e5e",
"assets/assets/flags/ec.png": "bb6df093fe6f5176878629cfe333e244",
"assets/assets/flags/ee.png": "76da59c628215587aba2dc523a8c5762",
"assets/assets/flags/eg.png": "6fea70efbf07249f9bae2540318cc3ca",
"assets/assets/flags/eh.png": "8c0f1bb9e60a27cd163914afc3ff257c",
"assets/assets/flags/er.png": "7acd540f0ce35abb71f3c66ad62e4fca",
"assets/assets/flags/es.png": "2b4e0f6aecba1f29ea343d97764733d9",
"assets/assets/flags/et.png": "f2a68e0e4d8b413909906493aaf53a43",
"assets/assets/flags/fi.png": "c11c35c355a89b170654c70690c87dc7",
"assets/assets/flags/fj.png": "f7c251c93d3deed87a008ab66d592ed9",
"assets/assets/flags/fk.png": "cf9b3a5db290d5e978f5c902c31628bc",
"assets/assets/flags/fm.png": "915d3fa2d6df8f83634356f21a2bae9d",
"assets/assets/flags/fo.png": "bcac5e8ed62f02c250e027143b2cf17d",
"assets/assets/flags/fr.png": "d478f8a838906ebbc0f1ca437a2b0fb6",
"assets/assets/flags/ga.png": "2449c99ce481fc3172dfc44d43a3dd68",
"assets/assets/flags/gb-eng.png": "80637152d021b659a66014637b4a447a",
"assets/assets/flags/gb-nir.png": "92963f0dce1e585acaadefc47cc58c24",
"assets/assets/flags/gb-sct.png": "14c39f8fca31db5954b0055559a81da6",
"assets/assets/flags/gb-wls.png": "e2be51d4fa92a930f190896509ccd620",
"assets/assets/flags/gb.png": "74d947e76be53ddb5003b0ddfcd8089f",
"assets/assets/flags/gd.png": "b59455a2d802ae0a21b01c14ad68dce8",
"assets/assets/flags/ge.png": "2632f06750c9c080bdee3ce0bf169ae3",
"assets/assets/flags/gf.png": "2188024a83c0544c260cafbc8b3422f7",
"assets/assets/flags/gg.png": "8793236122d9cb78a751dba258430dd9",
"assets/assets/flags/gh.png": "500723e3853b208954d21bf4e19ea0ca",
"assets/assets/flags/gi.png": "afc42504b1e5f0377adbdc7568d6fcec",
"assets/assets/flags/gl.png": "ac63e2e0be1360a07618d5cc93570dff",
"assets/assets/flags/gm.png": "0c96775c63bcc77b43004acf0a46bfaa",
"assets/assets/flags/gn.png": "3ce9831c366eea2251e8b67f7eb04cb7",
"assets/assets/flags/gp.png": "7aa215b076962b1d75f676d44d9aed62",
"assets/assets/flags/gq.png": "9bb9774718847c5facd4480ac21841cb",
"assets/assets/flags/gr.png": "98e688c1ca787e0c210f700f5b1beb7d",
"assets/assets/flags/gs.png": "e28e24f64e6a4adfd8b78b12038208f8",
"assets/assets/flags/gt.png": "6b38cfcbafd0439a3e84226622a612d0",
"assets/assets/flags/gu.png": "0652f5a63d1ddfa786d6bddc6bab1eb0",
"assets/assets/flags/gw.png": "fa2becd268de239764f4bdd265810826",
"assets/assets/flags/gy.png": "e94f18f62ec3e12c186c3e917083b8ca",
"assets/assets/flags/hk.png": "6b35b780583f668cb0c241b8a240a109",
"assets/assets/flags/hm.png": "ef52406be78c0c7eca8a1381ac8e4487",
"assets/assets/flags/hn.png": "5e3620d1698a1db1d861ee8b545dab34",
"assets/assets/flags/hr.png": "3476cedbfe5a47cc1191850d25944ffa",
"assets/assets/flags/ht.png": "408e09f48853fff43408c6562316aca4",
"assets/assets/flags/hu.png": "cd317e56facc2edc298dc57c8aef3192",
"assets/assets/flags/id.png": "5d02c6a088e46bb69a3ae7cb98149bd6",
"assets/assets/flags/ie.png": "267fbc264361b91f3a943f46d9dd647b",
"assets/assets/flags/il.png": "ada0431cfa35b7e0555a3349b2eb4ec7",
"assets/assets/flags/im.png": "1269ca384b55f0550cab253c186ebb14",
"assets/assets/flags/in.png": "f5fcecb2ed134243e039c1f757d1e416",
"assets/assets/flags/io.png": "7f47054b5356f48e58498bbcbadd3f9c",
"assets/assets/flags/iq.png": "f38b98ea5b189eb0cb727bde2f57c883",
"assets/assets/flags/ir.png": "754db293ad8278bc31f593fb1e212c85",
"assets/assets/flags/is.png": "7083992f2942e16da894b56d454e1216",
"assets/assets/flags/it.png": "c7c7b696ee165120b3a3840fd561fe0b",
"assets/assets/flags/je.png": "cfc5ea6745cc58220cc9772675899339",
"assets/assets/flags/jm.png": "bed807bafdc446d4beaea91ab0769adc",
"assets/assets/flags/jo.png": "31d4e3828d622a146a6978b6a6a72d31",
"assets/assets/flags/jp.png": "d1ed74a8462d06dd171b8a707e393b74",
"assets/assets/flags/ke.png": "5d79a8893f63a3fa345a0c4afa5f21fd",
"assets/assets/flags/kg.png": "c9ad6f2aac349aad87c4c5dcf69919b7",
"assets/assets/flags/kh.png": "a53a3429571669eca14ea9879987d2d7",
"assets/assets/flags/ki.png": "4bf4d3995b490436c71f0b3e33b5b039",
"assets/assets/flags/km.png": "775fa012e3c4749869f735ec34dff739",
"assets/assets/flags/kn.png": "a51d4ff1a8e43d4afd081df58228253d",
"assets/assets/flags/kp.png": "3bb360990a297b1ee7dddcee10853a8f",
"assets/assets/flags/kr.png": "fd4143b4e9b4b7c7888619bb60eab269",
"assets/assets/flags/kw.png": "852cb6f9b201a73491bb1d82a2740fcb",
"assets/assets/flags/ky.png": "a1605b9a8d15d67eb5e191367a904c6f",
"assets/assets/flags/kz.png": "a0f46fcfc88b9f0a05217bcd633b954a",
"assets/assets/flags/la.png": "5d5bb86a9c0e2d575ff18a43aecad0de",
"assets/assets/flags/lb.png": "6a4dae73d2ddcef60c6810ec010a2946",
"assets/assets/flags/lc.png": "114a04cda6d4ee203891a116da720bc0",
"assets/assets/flags/li.png": "0d47b9a913411e016d2596d17a86b9c2",
"assets/assets/flags/lk.png": "b19fe98a0c01eb63cff886f279eb8982",
"assets/assets/flags/lr.png": "01e2d33846e721724e7aabee455af35e",
"assets/assets/flags/ls.png": "2d52907c163091432e891ac41595dbb8",
"assets/assets/flags/lt.png": "225536996081c3a366aa7bfbf90b905d",
"assets/assets/flags/lu.png": "24524cfb0dd32e2a936d83a5eb25453f",
"assets/assets/flags/lv.png": "6ae36ff36a769a4dbe010ca704581433",
"assets/assets/flags/ly.png": "35722b7d0e77eb8eef7fb16396380ac7",
"assets/assets/flags/ma.png": "6fc48da69b9522204ffa4d9cd0ac4045",
"assets/assets/flags/mc.png": "c8c63ee911cab72681961d11374cb86e",
"assets/assets/flags/md.png": "77896fd9c2979ce8a98791b912151c1f",
"assets/assets/flags/me.png": "0c28d0a62b6aefe2ce362a9939f5e211",
"assets/assets/flags/mf.png": "d478f8a838906ebbc0f1ca437a2b0fb6",
"assets/assets/flags/mg.png": "51c3baf95e1607662e81466a66b97a50",
"assets/assets/flags/mh.png": "876831f286dc56b112442c852bea2361",
"assets/assets/flags/mk.png": "b5e4c0ae38222c470920b60916a9ff46",
"assets/assets/flags/ml.png": "ddfdbaf0514db57b9a36cc8c3fb74b1b",
"assets/assets/flags/mm.png": "94a9043a7d8c2fc432ea0c8793efa32f",
"assets/assets/flags/mn.png": "a9e8b77af24fa84c956172280a7f4d59",
"assets/assets/flags/mo.png": "3c5b19562abae38bad5fa3e23256118f",
"assets/assets/flags/mp.png": "38ce11b9ab1248764a5c32d255f3dac3",
"assets/assets/flags/mq.png": "203593c54336e784daad4742eb78d9f9",
"assets/assets/flags/mr.png": "a78fd151402fc3833f27db9c9c6af14e",
"assets/assets/flags/ms.png": "a3e67a7cfde2417ef0c362df1a60f7e4",
"assets/assets/flags/mt.png": "3634ef3b7d01e8e06333d1935f013cd9",
"assets/assets/flags/mu.png": "c762633f8b29038d3a650d6be812f59c",
"assets/assets/flags/mv.png": "3317dace601483ca48cc2aedaa24530c",
"assets/assets/flags/mw.png": "e470abbca8fbf71c0a7e52db8eb22700",
"assets/assets/flags/mx.png": "bf9add454838fe8833f3edd7c0f86cb1",
"assets/assets/flags/my.png": "8872fe5d5521b3bc220028c99f341f4f",
"assets/assets/flags/mz.png": "c75d83a28a670f52ed26406bf9d33dbd",
"assets/assets/flags/na.png": "a3adf5406bc312f176cff294e90f51f8",
"assets/assets/flags/nc.png": "4dcb04f8f798e3cf7ab55ea6d972107b",
"assets/assets/flags/ne.png": "cbe30a1349b439f77a0fda5a84416738",
"assets/assets/flags/nf.png": "69b5829a12daa6f0e915587068a0aace",
"assets/assets/flags/ng.png": "f67dee97a244ab271fbe05039533f4d6",
"assets/assets/flags/ni.png": "0ccfb4a740408eb749a49b7e0723e242",
"assets/assets/flags/nl.png": "8e543c0cc19192ba173370caec276542",
"assets/assets/flags/no.png": "3afab54f2d4f9c42b9532c2c95806b5f",
"assets/assets/flags/np.png": "c894afca92a194e8fb75794ffe335c43",
"assets/assets/flags/nr.png": "3461841ee2feccd555d0c69729052326",
"assets/assets/flags/nu.png": "eae8d3794ab8d754d762533518ac052c",
"assets/assets/flags/nz.png": "bc43f66ed2fadefcee73c096eafe8eef",
"assets/assets/flags/om.png": "75c4a9ec76dff3e8b556743f2b20f337",
"assets/assets/flags/pa.png": "14765e25e37222fcc79f1f547748e171",
"assets/assets/flags/pe.png": "bc02c208c16541319873cbe0577a0011",
"assets/assets/flags/pf.png": "6536c6d418019351291c069ccedacabf",
"assets/assets/flags/pg.png": "7c3aebca74594c426af2ce718f1732f7",
"assets/assets/flags/ph.png": "e71c236c0e974c0609f898de5f869b33",
"assets/assets/flags/pk.png": "233902b2148dd672f1b075aa99a99013",
"assets/assets/flags/pl.png": "a1262c8fc85e18e5e24d60dd0496a402",
"assets/assets/flags/pm.png": "bb67a208bb549c156fd05fe9f835a1eb",
"assets/assets/flags/pn.png": "f57c1b3b74aa46649a21697102171480",
"assets/assets/flags/pr.png": "98b78a317649dadc22e1c75be1d896f6",
"assets/assets/flags/ps.png": "3bb114a57b90132d4e5e984b33335db1",
"assets/assets/flags/pt.png": "e38791e06e723b3d2b7effda933310a2",
"assets/assets/flags/pw.png": "33d4c0332d958b22e1568e954e60cba6",
"assets/assets/flags/py.png": "2d4b32406f231f2d4c927ef5d5856364",
"assets/assets/flags/qa.png": "ccf9cb0b2f92152bd96d0c92d22480ee",
"assets/assets/flags/re.png": "dda4be0942af96b019f19249db91cec7",
"assets/assets/flags/ro.png": "0e11a687f714fd9128ae4d1064f7ad2e",
"assets/assets/flags/rs.png": "71195fc2818b8a754c50c7cddb18b005",
"assets/assets/flags/ru.png": "7901c9ebadadc5068dadd29be855832b",
"assets/assets/flags/rw.png": "3c262db719449b114d68f389f1e82f99",
"assets/assets/flags/sa.png": "8a0bc3befb437fa4f01d94a786317e4c",
"assets/assets/flags/sb.png": "987c55e6aaa8fc0d74e5673efd2712d8",
"assets/assets/flags/sc.png": "a49ae0019c9ac5ee12f9d6100c74d791",
"assets/assets/flags/sd.png": "69b183fc5b1a6ab2c5de3c58d4ccf0c8",
"assets/assets/flags/se.png": "ea3b397ffdae0f3d3762dde921c09864",
"assets/assets/flags/sg.png": "43c4d92355ba817ad8fd382fed0bdd6e",
"assets/assets/flags/sh.png": "144542c2e03d1436491730b565dee97b",
"assets/assets/flags/si.png": "a632ac0afcef16ba6f7d6ec8c2e30236",
"assets/assets/flags/sj.png": "3afab54f2d4f9c42b9532c2c95806b5f",
"assets/assets/flags/sk.png": "f03fa6ad39be47bef349adea66f83bfa",
"assets/assets/flags/sl.png": "359d05fc4fdeae5d922d3bfb4ccc52a7",
"assets/assets/flags/sm.png": "ee75bdf13cc7cef28051f75f53049838",
"assets/assets/flags/sn.png": "7b05b4537d395bc808f9c6cc14290225",
"assets/assets/flags/so.png": "10a4d9bc02094d55abe25e3d8e63afec",
"assets/assets/flags/sr.png": "f794084656d5a6c4c6c3501ab3cb4112",
"assets/assets/flags/ss.png": "8b19f04f86c889e9d3951b2a32517ec6",
"assets/assets/flags/st.png": "3c27d392330463f2d3672298922650cc",
"assets/assets/flags/sv.png": "13333398baa5c8674c351fd1cc35c82d",
"assets/assets/flags/sx.png": "f19eb02b81471d50e5e13ba0d1deb23a",
"assets/assets/flags/sy.png": "dd1f1d95dd2647b240d544193ff968c8",
"assets/assets/flags/sz.png": "2fb3ee5f502600bbfbf1f69b9519c91b",
"assets/assets/flags/tc.png": "add27d9d7aa3e4866d53a56744debd5f",
"assets/assets/flags/td.png": "ce82ae0506ece64545321a5377474eaf",
"assets/assets/flags/tf.png": "a9d4fdeba2f01afedcbba1a872f1809e",
"assets/assets/flags/tg.png": "c9e08b592b2fec9bce970c8517423568",
"assets/assets/flags/th.png": "5533bc0f00c3bc37ab0842ab80aadc5c",
"assets/assets/flags/tj.png": "c1cf53463e7a5b6f4c96a9dc6f9fb1fd",
"assets/assets/flags/tk.png": "db35158ac2a0a55c493a0b5ff76eabe6",
"assets/assets/flags/tl.png": "a3a2ef1b80b901d0e3691d3c5e2122f9",
"assets/assets/flags/tm.png": "c3d86d2cbdbe6e43e609272bb1bab877",
"assets/assets/flags/tn.png": "c3f8fc0f3653b6be121932ffa8ab7f86",
"assets/assets/flags/to.png": "cbaabf4f467712194b2ddbd92cfc87b4",
"assets/assets/flags/tr.png": "5fefa1e738b7333c506dc9c4f1926be7",
"assets/assets/flags/tt.png": "cc300a2c113fecc1aae781f3b0484047",
"assets/assets/flags/tv.png": "c1c04154b40cae1cea269d4bf4afc887",
"assets/assets/flags/tw.png": "eaa6f8236a9f961a4080bf9406f01019",
"assets/assets/flags/tz.png": "4c98373384ae8837324a5af6efb86a1e",
"assets/assets/flags/ua.png": "d4b609a5bbbb93f2e2ea8dd01b4c940c",
"assets/assets/flags/ug.png": "79a642025c18283a7c48202d5c5aba00",
"assets/assets/flags/um.png": "6b0ba712eed6429501c6aa785def833c",
"assets/assets/flags/us.png": "6b0ba712eed6429501c6aa785def833c",
"assets/assets/flags/uy.png": "f3ec824424d25b4338a5d9f3b2de5afb",
"assets/assets/flags/uz.png": "66bb5a2432fd0ea75b178399fca70f11",
"assets/assets/flags/va.png": "00980488c07e0673801a53ce728fc604",
"assets/assets/flags/vc.png": "13a2b49ffef700507de17407db38398f",
"assets/assets/flags/ve.png": "2ad40789351503587c07d6ae73cc9a70",
"assets/assets/flags/vg.png": "da75c9cfa49a10d7d6d0b6fc46292e72",
"assets/assets/flags/vi.png": "b5b39a36a36322c5744e28625294e413",
"assets/assets/flags/vn.png": "6705d2f4d75cef59b63c5531714ab84e",
"assets/assets/flags/vu.png": "a73c555118b5aa508867514427811a33",
"assets/assets/flags/wf.png": "26d068befe64cb470fb1f6498ce3054a",
"assets/assets/flags/ws.png": "9c91008fa7f87ec15f873ad9ffe20e6b",
"assets/assets/flags/xk.png": "f083705011263a9938898f79e2ad105b",
"assets/assets/flags/ye.png": "76494107ddc388cdc78fbbb21b9cf5fd",
"assets/assets/flags/yt.png": "bac61dbde5ff542463b91d963406f27c",
"assets/assets/flags/za.png": "2fb54b990dbb08e4a4b8a7a6783ef54f",
"assets/assets/flags/zm.png": "cfd3a8c3cee07f790990487387f3e770",
"assets/assets/flags/zw.png": "2efb37ae491eaf8341bc04e7bcbd96b6",
"assets/FontManifest.json": "dc2459bd150319353fb0333cf8c0c5d6",
"assets/fonts/MaterialIcons-Regular.otf": "930da5ef1f716e38e218acecf99ac833",
"assets/fonts/Pacifico/Pacifico-Regular.ttf": "85bb2d0ec4a0da159de42e89089ccc0b",
"assets/fonts/Red_Hat_Display/RedHatDisplay-VariableFont_wght.ttf": "3147836655ff1d321b20880ba1900a8f",
"assets/fonts/Sofia/Sofia-Regular.ttf": "e90830847756d0553db14d8b1c57a495",
"assets/NOTICES": "29c880c4406792954d2d81449663cd3a",
"assets/packages/cupertino_icons/assets/CupertinoIcons.ttf": "e986ebe42ef785b27164c36a9abc7818",
"assets/shaders/ink_sparkle.frag": "ecc85a2e95f5e9f53123dcaf8cb9b6ce",
"canvaskit/canvaskit.js": "738255d00768497e86aa4ca510cce1e1",
"canvaskit/canvaskit.js.symbols": "74a84c23f5ada42fe063514c587968c6",
"canvaskit/canvaskit.wasm": "9251bb81ae8464c4df3b072f84aa969b",
"canvaskit/chromium/canvaskit.js": "901bb9e28fac643b7da75ecfd3339f3f",
"canvaskit/chromium/canvaskit.js.symbols": "ee7e331f7f5bbf5ec937737542112372",
"canvaskit/chromium/canvaskit.wasm": "399e2344480862e2dfa26f12fa5891d7",
"canvaskit/skwasm.js": "5d4f9263ec93efeb022bb14a3881d240",
"canvaskit/skwasm.js.symbols": "c3c05bd50bdf59da8626bbe446ce65a3",
"canvaskit/skwasm.wasm": "4051bfc27ba29bf420d17aa0c3a98bce",
"canvaskit/skwasm.worker.js": "bfb704a6c714a75da9ef320991e88b03",
"favicon.png": "d4f9b9b5b1d215a45937e1aa2bd9ac50",
"flutter.js": "383e55f7f3cce5be08fcf1f3881f585c",
"flutter_bootstrap.js": "b41e32cd9fe04f325dde9b51d762d2e0",
"icons/apple-touch-icon.png": "152912004c3583aeb818b8e13c8ec9bd",
"icons/favicon.ico": "ecebd8eb3d25646d578b146cb7241071",
"icons/icon-192-maskable.png": "bdd84dd239115b9b036ce1e2e4d2972f",
"icons/icon-192.png": "152fb1a071859a6a841140938266e63c",
"icons/icon-512-maskable.png": "b5b95adfcbf0928b407b522fc50074ce",
"icons/icon-512.png": "0177d0c3f9c0637c630041e01f96d674",
"icons/Icon-maskable-192.png": "152fb1a071859a6a841140938266e63c",
"icons/Icon-maskable-512.png": "0177d0c3f9c0637c630041e01f96d674",
"index.html": "d5af1251bb7e9964bac06aeb3b2737b7",
"/": "d5af1251bb7e9964bac06aeb3b2737b7",
"main.dart.js": "a1afd80e0711165a2e9cea2609961bf1",
"manifest.json": "492d480ae5ebad5f2bc25c6e2e5cff6a",
"version.json": "28a74302b1a85a86ef3c3957bc874011"};
// The application shell files that are downloaded before a service worker can
// start.
const CORE = ["main.dart.js",
"index.html",
"flutter_bootstrap.js",
"assets/AssetManifest.bin.json",
"assets/FontManifest.json"];

// During install, the TEMP cache is populated with the application shell files.
self.addEventListener("install", (event) => {
  self.skipWaiting();
  return event.waitUntil(
    caches.open(TEMP).then((cache) => {
      return cache.addAll(
        CORE.map((value) => new Request(value, {'cache': 'reload'})));
    })
  );
});
// During activate, the cache is populated with the temp files downloaded in
// install. If this service worker is upgrading from one with a saved
// MANIFEST, then use this to retain unchanged resource files.
self.addEventListener("activate", function(event) {
  return event.waitUntil(async function() {
    try {
      var contentCache = await caches.open(CACHE_NAME);
      var tempCache = await caches.open(TEMP);
      var manifestCache = await caches.open(MANIFEST);
      var manifest = await manifestCache.match('manifest');
      // When there is no prior manifest, clear the entire cache.
      if (!manifest) {
        await caches.delete(CACHE_NAME);
        contentCache = await caches.open(CACHE_NAME);
        for (var request of await tempCache.keys()) {
          var response = await tempCache.match(request);
          await contentCache.put(request, response);
        }
        await caches.delete(TEMP);
        // Save the manifest to make future upgrades efficient.
        await manifestCache.put('manifest', new Response(JSON.stringify(RESOURCES)));
        // Claim client to enable caching on first launch
        self.clients.claim();
        return;
      }
      var oldManifest = await manifest.json();
      var origin = self.location.origin;
      for (var request of await contentCache.keys()) {
        var key = request.url.substring(origin.length + 1);
        if (key == "") {
          key = "/";
        }
        // If a resource from the old manifest is not in the new cache, or if
        // the MD5 sum has changed, delete it. Otherwise the resource is left
        // in the cache and can be reused by the new service worker.
        if (!RESOURCES[key] || RESOURCES[key] != oldManifest[key]) {
          await contentCache.delete(request);
        }
      }
      // Populate the cache with the app shell TEMP files, potentially overwriting
      // cache files preserved above.
      for (var request of await tempCache.keys()) {
        var response = await tempCache.match(request);
        await contentCache.put(request, response);
      }
      await caches.delete(TEMP);
      // Save the manifest to make future upgrades efficient.
      await manifestCache.put('manifest', new Response(JSON.stringify(RESOURCES)));
      // Claim client to enable caching on first launch
      self.clients.claim();
      return;
    } catch (err) {
      // On an unhandled exception the state of the cache cannot be guaranteed.
      console.error('Failed to upgrade service worker: ' + err);
      await caches.delete(CACHE_NAME);
      await caches.delete(TEMP);
      await caches.delete(MANIFEST);
    }
  }());
});
// The fetch handler redirects requests for RESOURCE files to the service
// worker cache.
self.addEventListener("fetch", (event) => {
  if (event.request.method !== 'GET') {
    return;
  }
  var origin = self.location.origin;
  var key = event.request.url.substring(origin.length + 1);
  // Redirect URLs to the index.html
  if (key.indexOf('?v=') != -1) {
    key = key.split('?v=')[0];
  }
  if (event.request.url == origin || event.request.url.startsWith(origin + '/#') || key == '') {
    key = '/';
  }
  // If the URL is not the RESOURCE list then return to signal that the
  // browser should take over.
  if (!RESOURCES[key]) {
    return;
  }
  // If the URL is the index.html, perform an online-first request.
  if (key == '/') {
    return onlineFirst(event);
  }
  event.respondWith(caches.open(CACHE_NAME)
    .then((cache) =>  {
      return cache.match(event.request).then((response) => {
        // Either respond with the cached resource, or perform a fetch and
        // lazily populate the cache only if the resource was successfully fetched.
        return response || fetch(event.request).then((response) => {
          if (response && Boolean(response.ok)) {
            cache.put(event.request, response.clone());
          }
          return response;
        });
      })
    })
  );
});
self.addEventListener('message', (event) => {
  // SkipWaiting can be used to immediately activate a waiting service worker.
  // This will also require a page refresh triggered by the main worker.
  if (event.data === 'skipWaiting') {
    self.skipWaiting();
    return;
  }
  if (event.data === 'downloadOffline') {
    downloadOffline();
    return;
  }
});
// Download offline will check the RESOURCES for all files not in the cache
// and populate them.
async function downloadOffline() {
  var resources = [];
  var contentCache = await caches.open(CACHE_NAME);
  var currentContent = {};
  for (var request of await contentCache.keys()) {
    var key = request.url.substring(origin.length + 1);
    if (key == "") {
      key = "/";
    }
    currentContent[key] = true;
  }
  for (var resourceKey of Object.keys(RESOURCES)) {
    if (!currentContent[resourceKey]) {
      resources.push(resourceKey);
    }
  }
  return contentCache.addAll(resources);
}
// Attempt to download the resource online before falling back to
// the offline cache.
function onlineFirst(event) {
  return event.respondWith(
    fetch(event.request).then((response) => {
      return caches.open(CACHE_NAME).then((cache) => {
        cache.put(event.request, response.clone());
        return response;
      });
    }).catch((error) => {
      return caches.open(CACHE_NAME).then((cache) => {
        return cache.match(event.request).then((response) => {
          if (response != null) {
            return response;
          }
          throw error;
        });
      });
    })
  );
}
