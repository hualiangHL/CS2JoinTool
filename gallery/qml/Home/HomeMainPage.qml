import QtQuick
import QtQuick.Controls.Basic
import QtQuick.Layouts
import HuskarUI.Basic
import Gallery


Item {
    id: root


    ServerQueryEngine { id: exgEng }
    ZedServerQueryEngine { id: zedEng }
    UbServerQueryEngine { id: ubEng }
    FysServerQueryEngine { id: fysEng }
    UpkkServerQueryEngine { id: upkkEng }
    StarServerQueryEngine { id: starEng }
    InternationalServerQueryEngine { id: intEng }
    MapRunServerQueryEngine { id: maprunEng }

    MapTranslator {
        id: homeMapTrans
        Component.onCompleted: setEnglish(Lang.isEn())
    }


    property int onlineTotal: 0
    property int playersTotal: 0
    property var communityRows: []
    property int maxCommunityOnline: 1
    property int maxCommunityPlayers: 1


    property string dailyQuote: (function() {
        var quotes = [
            { t: Lang.tr('少壮不努力，老大徒伤悲。','If you do not study hard when young, you will regret it in old age.'), b: Lang.tr('汉乐府','Han Yuefu') },
            { t: Lang.tr('千里之行，始于足下。','A journey of a thousand miles begins with a single step.'), b: Lang.tr('老子','Laozi') },
            { t: Lang.tr('锲而不舍，金石可镂。','With persistence, metal and stone can be carved.'), b: Lang.tr('荀子','Xunzi') },
            { t: Lang.tr('莫愁前路无知己，天下谁人不识君。','Do not worry about having no friends ahead; who does not know you?'), b: Lang.tr('高适','Gao Shi') },
            { t: Lang.tr('读书破万卷，下笔如有神。','Read ten thousand volumes and write as if aided by gods.'), b: Lang.tr('杜甫','Du Fu') },
            { t: Lang.tr('会当凌绝顶，一览众山小。','One day I will top the peak and see all mountains at a glance.'), b: Lang.tr('杜甫','Du Fu') },
            { t: Lang.tr('海内存知己，天涯若比邻。','A bosom friend afar brings a distant land near.'), b: Lang.tr('王勃','Wang Bo') },
            { t: Lang.tr('老骥伏枥，志在千里。','An old steed in the stable still aspires to run a thousand li.'), b: Lang.tr('曹操','Cao Cao') },
            { t: Lang.tr('业精于勤，荒于嬉。','Proficiency comes from diligence and is ruined by idleness.'), b: Lang.tr('韩愈','Han Yu') },
            { t: Lang.tr('三人行，必有我师焉。','When three walk together, one of them can teach me.'), b: Lang.tr('孔子','Confucius') },
            { t: Lang.tr('知己知彼，百战不殆。','Know yourself and your enemy, and you win a hundred battles.'), b: Lang.tr('孙子','Sun Tzu') },
            { t: Lang.tr('生当作人杰，死亦为鬼雄。','Live as a hero, die as a heroic ghost.'), b: Lang.tr('李清照','Li Qingzhao') },
            { t: Lang.tr('富贵不能淫，贫贱不能移。','Wealth cannot corrupt, poverty cannot move me.'), b: Lang.tr('孟子','Mencius') },
            { t: Lang.tr('天生我材必有用，千金散尽还复来。','Heaven gave me talents for a purpose; gold spent will return.'), b: Lang.tr('李白','Li Bai') },
            { t: Lang.tr('长风破浪会有时，直挂云帆济沧海。','The time will come to ride the wind and waves and sail the vast sea.'), b: Lang.tr('李白','Li Bai') },
            { t: Lang.tr('山重水复疑无路，柳暗花明又一村。','Beyond the hills and streams, a village appears amid willows and flowers.'), b: Lang.tr('陆游','Lu You') },
            { t: Lang.tr('沉舟侧畔千帆过，病树前头万木春。','A thousand sails pass the sunken boat; ten thousand trees bloom by the withered one.'), b: Lang.tr('刘禹锡','Liu Yuxi') },
            { t: Lang.tr('纸上得来终觉浅，绝知此事要躬行。','What you learn from books is shallow; true knowledge needs practice.'), b: Lang.tr('陆游','Lu You') },
            { t: Lang.tr('不畏浮云遮望眼，自缘身在最高层。','Undaunted by clouds, for I stand on the highest floor.'), b: Lang.tr('王安石','Wang Anshi') },
            { t: Lang.tr('天行健，君子以自强不息。','As heaven moves with vigor, a gentleman strives ceaselessly.'), b: Lang.tr('周易','I Ching') },
            { t: Lang.tr('路漫漫其修远兮，吾将上下而求索。','The road is long; I will search high and low.'), b: Lang.tr('屈原','Qu Yuan') },
            { t: Lang.tr('先天下之忧而忧，后天下之乐而乐。','Worry before the world worries; rejoice after it rejoices.'), b: Lang.tr('范仲淹','Fan Zhongyan') },
            { t: Lang.tr('志不立，天下无可成之事。','Without a goal, nothing can be achieved.'), b: Lang.tr('王阳明','Wang Yangming') },
            { t: Lang.tr('玉不琢不成器，人不学不知义。','Jade uncut is not a vessel; a person untaught knows no right.'), b: Lang.tr('三字经','Three Character Classic') },
            { t: Lang.tr('黑发不知勤学早，白首方悔读书迟。','If youth does not study early, white hair regrets reading late.'), b: Lang.tr('颜真卿','Yan Zhenqing') },
            { t: Lang.tr('书山有路勤为径，学海无涯苦作舟。','Diligence is the path up the mountain of books; hard work the boat on the sea of learning.'), b: Lang.tr('韩愈','Han Yu') },
            { t: Lang.tr('一寸光阴一寸金，寸金难买寸光阴。','An inch of time is an inch of gold, but gold cannot buy time.'), b: Lang.tr('增广贤文','Zeng Guang Xian Wen') },
            { t: Lang.tr('良药苦口利于病，忠言逆耳利于行。','Good medicine tastes bitter; good advice is hard to hear.'), b: Lang.tr('史记','Records of the Grand Historian') },
            { t: Lang.tr('踏破铁鞋无觅处，得来全不费工夫。','You search everywhere in vain, then find it without effort.'), b: Lang.tr('罗贯中','Luo Guanzhong') },
            { t: Lang.tr('只要功夫深，铁杵磨成针。','With enough effort, an iron pestle becomes a needle.'), b: Lang.tr('民间','Folk') },
            { t: Lang.tr('欲穷千里目，更上一层楼。','To see a thousand li further, climb one more floor.'), b: Lang.tr('王之涣','Wang Zhihuan') },
            { t: Lang.tr('春眠不觉晓，处处闻啼鸟。','Sleeping through spring dawn, hearing birds everywhere.'), b: Lang.tr('孟浩然','Meng Haoran') },
            { t: Lang.tr('床前明月光，疑是地上霜。','Moonlight before my bed seems like frost on the ground.'), b: Lang.tr('李白','Li Bai') },
            { t: Lang.tr('举头望明月，低头思故乡。','I raise my head to the moon, lower it and think of home.'), b: Lang.tr('李白','Li Bai') },
            { t: Lang.tr('谁知盘中餐，粒粒皆辛苦。','Who knows each grain on the plate is hard-earned toil?'), b: Lang.tr('李绅','Li Shen') },
            { t: Lang.tr('锄禾日当午，汗滴禾下土。','Hoeing rice at noon, sweat dripping into the soil.'), b: Lang.tr('李绅','Li Shen') },
            { t: Lang.tr('红豆生南国，春来发几枝。','Red beans grow in the south; how many sprout in spring?'), b: Lang.tr('王维','Wang Wei') },
            { t: Lang.tr('大漠孤烟直，长河落日圆。','Lone smoke rises straight over the desert; the sun sets round on the long river.'), b: Lang.tr('王维','Wang Wei') },
            { t: Lang.tr('独在异乡为异客，每逢佳节倍思亲。','Alone in a strange land, I miss my kin doubly on holidays.'), b: Lang.tr('王维','Wang Wei') },
            { t: Lang.tr('朝辞白帝彩云间，千里江陵一日还。','Leaving Baidicheng amid clouds, Jiangling returns in one day.'), b: Lang.tr('李白','Li Bai') },
            { t: Lang.tr('飞流直下三千尺，疑是银河落九天。','A three-thousand-foot torrent, as if the Milky Way falls from the sky.'), b: Lang.tr('李白','Li Bai') },
            { t: Lang.tr('两岸猿声啼不住，轻舟已过万重山。','Apes cry on both banks; the light boat has passed ten thousand mountains.'), b: Lang.tr('李白','Li Bai') },
            { t: Lang.tr('孤帆远影碧空尽，唯见长江天际流。','The lone sail fades into the blue sky; only the Yangtze flows to the horizon.'), b: Lang.tr('李白','Li Bai') },
            { t: Lang.tr('故人西辞黄鹤楼，烟花三月下扬州。','My friend leaves Yellow Crane Tower for Yangzhou in March.'), b: Lang.tr('李白','Li Bai') },
            { t: Lang.tr('桃花潭水深千尺，不及汪伦送我情。','Peach Blossom Pool is a thousand feet deep, yet less than Wang Lun parting gift.'), b: Lang.tr('李白','Li Bai') },
            { t: Lang.tr('相看两不厌，只有敬亭山。','We gaze at each other, never tired: only I and Jingting Mountain.'), b: Lang.tr('李白','Li Bai') },
            { t: Lang.tr('小时不识月，呼作白玉盘。','As a child I knew not the moon and called it a white jade plate.'), b: Lang.tr('李白','Li Bai') },
            { t: Lang.tr('野火烧不尽，春风吹又生。','Wildfire never burns them out; spring wind brings them back to life.'), b: Lang.tr('白居易','Bai Juyi') },
            { t: Lang.tr('离离原上草，一岁一枯荣。','Grass on the plain flourishes and withers year by year.'), b: Lang.tr('白居易','Bai Juyi') },
            { t: Lang.tr('日出江花红胜火，春来江水绿如蓝。','At sunrise river flowers outshine fire; in spring the water is greener than indigo.'), b: Lang.tr('白居易','Bai Juyi') },
            { t: Lang.tr('乱花渐欲迷人眼，浅草才能没马蹄。','Flowers dazzle the eyes; shallow grass just covers horseshoes.'), b: Lang.tr('白居易','Bai Juyi') },
            { t: Lang.tr('同是天涯沦落人，相逢何必曾相识。','Fellow wanderers at the worlds end, why need we have met before?'), b: Lang.tr('白居易','Bai Juyi') },
            { t: Lang.tr('千呼万唤始出来，犹抱琵琶半遮面。','Called a thousand times, she comes, half-hiding her face behind the pipa.'), b: Lang.tr('白居易','Bai Juyi') },
            { t: Lang.tr('慈母手中线，游子身上衣。','The thread in a mothers hand clothes the wandering son.'), b: Lang.tr('孟郊','Meng Jiao') },
            { t: Lang.tr('谁言寸草心，报得三春晖。','Who says a blade of grass can repay the spring suns warmth?'), b: Lang.tr('孟郊','Meng Jiao') },
            { t: Lang.tr('春色满园关不住，一枝红杏出墙来。','Spring cannot be kept in the garden; a red apricot branch reaches over the wall.'), b: Lang.tr('叶绍翁','Ye Shaoweng') },
            { t: Lang.tr('等闲识得东风面，万紫千红总是春。','One glance at the east wind and you know: a riot of colors is spring.'), b: Lang.tr('朱熹','Zhu Xi') },
            { t: Lang.tr('问渠那得清如许，为有源头活水来。','Why is the pond so clear? Fresh water flows from its source.'), b: Lang.tr('朱熹','Zhu Xi') },
            { t: Lang.tr('接天莲叶无穷碧，映日荷花别样红。','Lotus leaves stretch to the sky; blossoms glow red in the sun.'), b: Lang.tr('杨万里','Yang Wanli') },
            { t: Lang.tr('小荷才露尖尖角，早有蜻蜓立上头。','A tiny lotus bud pokes out; a dragonfly already rests atop.'), b: Lang.tr('杨万里','Yang Wanli') },
            { t: Lang.tr('儿童急走追黄蝶，飞入菜花无处寻。','Children chase yellow butterflies into the rapeseed, lost to sight.'), b: Lang.tr('杨万里','Yang Wanli') },
            { t: Lang.tr('停车坐爱枫林晚，霜叶红于二月花。','I stop the cart for the evening maples: frost-kissed leaves redder than spring flowers.'), b: Lang.tr('杜牧','Du Mu') },
            { t: Lang.tr('远上寒山石径斜，白云生处有人家。','A stony path slopes up the cold hill; homes appear where clouds rise.'), b: Lang.tr('杜牧','Du Mu') },
            { t: Lang.tr('借问酒家何处有，牧童遥指杏花村。','Where is a tavern? The cowherd points to Apricot Village far away.'), b: Lang.tr('杜牧','Du Mu') },
            { t: Lang.tr('商女不知亡国恨，隔江犹唱后庭花。','Singing girls know no sorrow of a fallen state; they still sing Backyard Flowers.'), b: Lang.tr('杜牧','Du Mu') },
            { t: Lang.tr('春风又绿江南岸，明月何时照我还。','Spring wind greens the southern shore again; when will the moon light my way home?'), b: Lang.tr('王安石','Wang Anshi') },
            { t: Lang.tr('千门万户曈曈日，总把新桃换旧符。','Doors open to the bright sun; new peach charms replace the old.'), b: Lang.tr('王安石','Wang Anshi') },
            { t: Lang.tr('不识庐山真面目，只缘身在此山中。','You cannot see Lushans true face, for you are inside the mountain.'), b: Lang.tr('苏轼','Su Shi') },
            { t: Lang.tr('欲把西湖比西子，淡妆浓抹总相宜。','Compare the West Lake to Xishi: fair in light or heavy makeup.'), b: Lang.tr('苏轼','Su Shi') },
            { t: Lang.tr('竹外桃花三两枝，春江水暖鸭先知。','A few peach branches past the bamboo; ducks feel the river warming first.'), b: Lang.tr('苏轼','Su Shi') },
            { t: Lang.tr('荷尽已无擎雨盖，菊残犹有傲霜枝。','Lotus leaves are gone, yet chrysanthemum stems still brave the frost.'), b: Lang.tr('苏轼','Su Shi') },
            { t: Lang.tr('大江东去，浪淘尽，千古风流人物。','The great river flows east, washing away heroes of a thousand ages.'), b: Lang.tr('苏轼','Su Shi') },
            { t: Lang.tr('但愿人长久，千里共婵娟。','May we live long and share the moon across a thousand li.'), b: Lang.tr('苏轼','Su Shi') },
            { t: Lang.tr('人有悲欢离合，月有阴晴圆缺。','People have joys and sorrows; the moon waxes and wanes.'), b: Lang.tr('苏轼','Su Shi') },
            { t: Lang.tr('十年生死两茫茫，不思量，自难忘。','Ten years, dead and living, both unknowing; without thinking, how can I forget?'), b: Lang.tr('苏轼','Su Shi') },
            { t: Lang.tr('莫等闲，白了少年头，空悲切。','Do not idle away youth and lament your white hair in vain.'), b: Lang.tr('岳飞','Yue Fei') },
            { t: Lang.tr('三十功名尘与土，八千里路云和月。','Thirty years of fame like dust; eight thousand li under clouds and moon.'), b: Lang.tr('岳飞','Yue Fei') },
            { t: Lang.tr('位卑未敢忘忧国，事定犹须待阖棺。','Humbled, I never forget my country; the verdict waits for the coffin lid.'), b: Lang.tr('陆游','Lu You') },
            { t: Lang.tr('王师北定中原日，家祭无忘告乃翁。','When the royal army retakes the Central Plains, tell your father at the ancestral rites.'), b: Lang.tr('陆游','Lu You') },
            { t: Lang.tr('人生自古谁无死，留取丹心照汗青。','Since ancient times who does not die? Leave a loyal heart to shine in history.'), b: Lang.tr('文天祥','Wen Tianxiang') },
            { t: Lang.tr('粉骨碎身浑不怕，要留清白在人间。','Broken bones do not frighten me; I will leave my purity in the world.'), b: Lang.tr('于谦','Yu Qian') },
            { t: Lang.tr('千锤万凿出深山，烈火焚烧若等闲。','Hammered and chiseled from the deep mountains, indifferent to raging fire.'), b: Lang.tr('于谦','Yu Qian') },
            { t: Lang.tr('江山代有才人出，各领风骚数百年。','Every age has its talents leading the literary world for centuries.'), b: Lang.tr('赵翼','Zhao Yi') },
            { t: Lang.tr('落红不是无情物，化作春泥更护花。','Fallen petals are not heartless; they turn to soil to nourish flowers.'), b: Lang.tr('龚自珍','Gong Zizhen') },
            { t: Lang.tr('我劝天公重抖擞，不拘一格降人才。','I urge the heavens to rouse themselves and send talents of every kind.'), b: Lang.tr('龚自珍','Gong Zizhen') },
            { t: Lang.tr('苟利国家生死以，岂因祸福避趋之。','If it benefits my country, I give my life; I will not flee for weal or woe.'), b: Lang.tr('林则徐','Lin Zexu') },
            { t: Lang.tr('海纳百川，有容乃大。','The sea takes in all rivers; greatness lies in tolerance.'), b: Lang.tr('林则徐','Lin Zexu') },
            { t: Lang.tr('壁立千仞，无欲则刚。','Cliffs stand ten thousand feet; without desire one is strong.'), b: Lang.tr('林则徐','Lin Zexu') },
            { t: Lang.tr('横眉冷对千夫指，俯首甘为孺子牛。','Fierce brows to a thousand pointing fingers; bowed head, a willing ox for the children.'), b: Lang.tr('鲁迅','Lu Xun') },
            { t: Lang.tr('世上本没有路，走的人多了便成了路。','There is no road in the world; when many walk it, a road appears.'), b: Lang.tr('鲁迅','Lu Xun') },
            { t: Lang.tr('万两黄金容易得，知心一个也难求。','Ten thousand taels of gold are easy; one true friend is hard to find.'), b: Lang.tr('曹雪芹','Cao Xueqin') },
            { t: Lang.tr('满纸荒唐言，一把辛酸泪。','Pages full of nonsense, a handful of bitter tears.'), b: Lang.tr('曹雪芹','Cao Xueqin') },
            { t: Lang.tr('世事洞明皆学问，人情练达即文章。','Understanding the world is learning; mastering human affairs is literature.'), b: Lang.tr('曹雪芹','Cao Xueqin') },
            { t: Lang.tr('金玉其外，败絮其中。','Fine gold and jade outside, rotten cotton within.'), b: Lang.tr('刘基','Liu Ji') },
            { t: Lang.tr('一年之计在于春，一日之计在于晨。','The years plan is spring; the days plan is dawn.'), b: Lang.tr('增广贤文','Zeng Guang Xian Wen') },
            { t: Lang.tr('路遥知马力，日久见人心。','A long road tests a horse; time reveals a heart.'), b: Lang.tr('增广贤文','Zeng Guang Xian Wen') },
            { t: Lang.tr('千里送鹅毛，礼轻情意重。','A goose feather sent a thousand li: a light gift, deep feeling.'), b: Lang.tr('谚语','Proverb') },
            { t: Lang.tr('临渊羡鱼，不如退而结网。','Better to go back and weave a net than envy fish by the pond.'), b: Lang.tr('汉书','Book of Han') },
            { t: Lang.tr('前事不忘，后事之师。','Past lessons are the teachers of the future.'), b: Lang.tr('战国策','Strategies of the Warring States') },
            { t: Lang.tr('亡羊补牢，为时未晚。','Mending the pen after the sheep is lost is not too late.'), b: Lang.tr('战国策','Strategies of the Warring States') }
        ]
        var d = new Date()
        var seed = d.getFullYear() * 10000 + (d.getMonth() + 1) * 100 + d.getDate()
        var idx = seed % quotes.length

        var y = new Date(d.getFullYear(), d.getMonth(), d.getDate() - 1)
        var ySeed = y.getFullYear() * 10000 + (y.getMonth() + 1) * 100 + y.getDate()
        var yIdx = ySeed % quotes.length
        if (idx === yIdx)
            idx = (idx + 1) % quotes.length
        var q = quotes[idx]
        return q.t + '          ' + '——' + q.b
    })()



    property int loadDone: 0
    property int loadTotal: 0
    property bool allLoaded: false


    function serverStats(eng) {
        let done = 0, total = 0
        if (!eng) return [0, 0]
        const gs = eng.groups
        for (const g of gs) {
            for (const s of g.servers) {
                total++
                if (!s.checking) done++
            }
        }
        return [done, total]
    }


    function refreshLoadProgress() {
        if (root.allLoaded) return
        let done = 0, total = 0
        const engs = [exgEng, zedEng, ubEng, fysEng, upkkEng, starEng, intEng, maprunEng]
        for (const e of engs) {
            const st = root.serverStats(e)
            done += st[0]
            total += st[1]
        }
        root.loadDone = done
        root.loadTotal = total
        if (total > 0 && done >= total) {
            root.allLoaded = true
        }
    }


    function refreshSummary() {
        const rows = [];
        const communities = [
            { name: Lang.tr('EXG社区','EXG Community'), short: 'EXG', eng: exgEng },
            { name: Lang.tr('僵尸乐园','Zombie Eden'), eng: zedEng, short: 'ZED' },
            { name: Lang.tr('UB社区','UB Community'), eng: ubEng, short: 'UB' },
            { name: Lang.tr('风云社','FYS'), eng: fysEng, short: 'FYS' },


            { name: Lang.tr('UPKK','UPKK'), eng: upkkEng, short: 'UPKK', group: 'x社区-upkk' },
            { name: Lang.tr('零次元社-zero','Zero Dimension - ZERO'), eng: upkkEng, short: 'ZERO', group: '零次元社-zero' },
            { name: Lang.tr('星社区','Star Community'), eng: starEng, short: Lang.tr('星社','STAR') },
            { name: Lang.tr('国际服','International'), eng: intEng, short: Lang.tr('国际','INTL') },
            { name: Lang.tr('跑图服','Map Run'), eng: maprunEng, short: Lang.tr('跑图','MAP') }
        ];
        let oTotal = 0, pTotal = 0;
        for (const c of communities) {
            let on = 0, pl = 0;
            const gs = c.eng.groups;
            for (const g of gs) {

                if (c.group !== undefined && g.name !== c.group) continue;
                for (const s of g.servers) {
                    if (s.online) {
                        on++;
                        const m = String(s.players).match(/^(\d+)/);
                        if (m) pl += parseInt(m[1], 10);
                    }
                }
            }
            oTotal += on;
            pTotal += pl;
            rows.push({ label: c.name, short: c.short, online: on, players: pl });
        }
        onlineTotal = oTotal;
        playersTotal = pTotal;
        communityRows = rows;
        maxCommunityOnline = Math.max.apply(null, rows.map(r => r.online)) || 1;
        maxCommunityPlayers = Math.max.apply(null, rows.map(r => r.players)) || 1;

        OnlineHistoryManager.record(playersTotal, onlineTotal);
    }


    Timer {
        interval: 60000
        running: true
        repeat: true
        onTriggered: {
            exgEng.refresh();
            zedEng.refresh();
            ubEng.refresh();
            fysEng.refresh();
            upkkEng.refresh();
            starEng.refresh();
            intEng.refresh();
            maprunEng.refresh();
            root.refreshSummary();
        }
    }
    Connections { target: exgEng; function onServersUpdated() { root.refreshSummary(); root.refreshLoadProgress() } }
    Connections { target: zedEng; function onServersUpdated() { root.refreshSummary(); root.refreshLoadProgress() } }
    Connections { target: ubEng; function onServersUpdated() { root.refreshSummary(); root.refreshLoadProgress() } }
    Connections { target: fysEng; function onServersUpdated() { root.refreshSummary(); root.refreshLoadProgress() } }
    Connections { target: upkkEng; function onServersUpdated() { root.refreshSummary(); root.refreshLoadProgress() } }
    Connections { target: starEng; function onServersUpdated() { root.refreshSummary(); root.refreshLoadProgress() } }
    Connections { target: intEng; function onServersUpdated() { root.refreshSummary(); root.refreshLoadProgress() } }
    Connections { target: maprunEng; function onServersUpdated() { root.refreshSummary(); root.refreshLoadProgress() } }

    Rectangle {
        anchors.fill: parent
        color: 'transparent'
        radius: 10
        border.color: HusThemeFunctions.alpha(HusTheme.Primary.colorSplit, 0.35)
        border.width: 1
    }


    Timer {
        interval: 1000
        running: true
        repeat: true
        onTriggered: refreshClock()
    }
    Component.onCompleted: {
        refreshClock()

        exgEng.refresh();
        zedEng.refresh();
        ubEng.refresh();
        fysEng.refresh();
        upkkEng.refresh();
        starEng.refresh();
        intEng.refresh();
        maprunEng.refresh();
        refreshSummary()
    }

    function refreshClock() {
        const d = new Date();
        const pad = n => String(n).padStart(2, '0');
        clockText.text = pad(d.getHours()) + ':' + pad(d.getMinutes()) + ':' + pad(d.getSeconds());
        const wd = [Lang.tr('星期日','Sunday'), Lang.tr('星期一','Monday'), Lang.tr('星期二','Tuesday'), Lang.tr('星期三','Wednesday'), Lang.tr('星期四','Thursday'), Lang.tr('星期五','Friday'), Lang.tr('星期六','Saturday')][d.getDay()];
        dateText.text = d.getFullYear() + '-' + pad(d.getMonth() + 1) + '-' + pad(d.getDate()) + ' ' + wd;
        const h = d.getHours();
        greetingText.text = h < 6 ? Lang.tr('凌晨好','Good night') : h < 12 ? Lang.tr('上午好','Good morning') : h < 18 ? Lang.tr('下午好','Good afternoon') : Lang.tr('晚上好','Good evening');
    }

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 16
        spacing: 12


        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: 92
            radius: 10
            color: HusThemeFunctions.alpha(HusTheme.Primary.colorBgContainer, 0.45)
            border.color: HusThemeFunctions.alpha(HusTheme.Primary.colorSplit, 0.5)
            border.width: 1

            Item {
                anchors.fill: parent


                Column {
                    anchors.left: parent.left
                    anchors.leftMargin: 20
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: 5

                    HusText {
                        id: greetingText
                        text: Lang.tr('下午好','Good afternoon')
                        color: HusTheme.Primary.colorPrimary
                        font.pixelSize: 24
                        font.weight: Font.DemiBold
                    }
                    HusText {
                        text: Lang.tr('很不高兴为你服务 今天你要做点什么','Not pleased to serve you. What do you need today?')
                        color: HusTheme.Primary.colorTextBase
                        font.pixelSize: 15
                        font.weight: Font.DemiBold
                    }
                    HusText {
                        text: root.dailyQuote
                        color: HusTheme.Primary.colorTextSecondary
                        font.pixelSize: 12
                    }
                }


                Column {
                    anchors.right: parent.right
                    anchors.rightMargin: 20
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: 2

                    HusText {
                        id: clockText
                        text: '--:--:--'
                        color: HusTheme.Primary.colorTextBase
                        font.pixelSize: 22
                        font.weight: Font.DemiBold
                        horizontalAlignment: Text.AlignRight
                    }
                    HusText {
                        id: dateText
                        text: '---- -- --'
                        color: HusTheme.Primary.colorTextSecondary
                        font.pixelSize: 12
                        horizontalAlignment: Text.AlignRight
                    }
                }
            }
        }


            RowLayout {
                Layout.fillWidth: true
                Layout.fillHeight: false
                Layout.preferredHeight: 78
                spacing: 12


                Rectangle {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    radius: 10
                    color: HusThemeFunctions.alpha(HusTheme.Primary.colorBgContainer, 0.45)
                    border.color: HusThemeFunctions.alpha(HusTheme.Primary.colorSplit, 0.5)
                    border.width: 1

                    Column {
                        anchors.left: parent.left
                        anchors.leftMargin: 14
                        anchors.verticalCenter: parent.verticalCenter
                        spacing: 2
                        HusText {
                            text: Lang.tr('在线服务器','Online Servers')
                            color: HusTheme.Primary.colorTextSecondary
                            font.pixelSize: 11
                        }
                        HusText {
                            text: root.onlineTotal
                            color: HusTheme.Primary.colorTextBase
                            font.pixelSize: 22
                            font.weight: Font.DemiBold
                        }
                    }
                }


                Rectangle {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    radius: 10
                    color: HusThemeFunctions.alpha(HusTheme.Primary.colorBgContainer, 0.45)
                    border.color: HusThemeFunctions.alpha(HusTheme.Primary.colorSplit, 0.5)
                    border.width: 1

                    Column {
                        anchors.left: parent.left
                        anchors.leftMargin: 14
                        anchors.verticalCenter: parent.verticalCenter
                        spacing: 2
                        HusText {
                            text: Lang.tr('在线玩家','Online Players')
                            color: HusTheme.Primary.colorTextSecondary
                            font.pixelSize: 11
                        }
                        HusText {
                            text: root.playersTotal
                            color: HusTheme.Primary.colorTextBase
                            font.pixelSize: 22
                            font.weight: Font.DemiBold
                        }
                    }
                }
            }



        RowLayout {
            Layout.fillWidth: true
            Layout.fillHeight: true
            spacing: 12


            ColumnLayout {
                Layout.fillWidth: true
                Layout.fillHeight: true
                spacing: 12




                Rectangle {
                    id: communityStatCard
                    Layout.fillWidth: true
                    Layout.fillHeight: false


                    Layout.preferredHeight: communityStatCol.implicitHeight + 24
                    radius: 10
                    color: HusThemeFunctions.alpha(HusTheme.Primary.colorBgContainer, 0.45)
                    border.color: HusThemeFunctions.alpha(HusTheme.Primary.colorSplit, 0.5)
                    border.width: 1

                    ColumnLayout {
                        id: communityStatCol
                        anchors.fill: parent
                        anchors.margins: 12


                        spacing: 3

                        HusText {
                            Layout.fillWidth: true
                            text: Lang.tr('各社区在线统计','Community Online Stats')
                            color: HusTheme.Primary.colorTextBase
                            font.pixelSize: 14
                            font.weight: Font.DemiBold
                        }

                        Repeater {
                            model: root.communityRows
                            delegate: Rectangle {
                                Layout.fillWidth: true
                                Layout.preferredHeight: 24
                                radius: 4

                                color: hoverMa.containsMouse
                                       ? HusThemeFunctions.alpha(HusTheme.Primary.colorBgContainer, 0.6)
                                       : HusThemeFunctions.alpha(HusTheme.Primary.colorBgContainer, 0)

                                Behavior on color { ColorAnimation { duration: 180; easing.type: Easing.OutCubic } }
                                MouseArea {
                                    id: hoverMa
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    acceptedButtons: Qt.NoButton
                                }

                                RowLayout {
                                    anchors.fill: parent
                                    anchors.leftMargin: 4
                                    anchors.rightMargin: 12
                                    spacing: 8

                                    Rectangle {
                                        Layout.preferredWidth: 3
                                        Layout.preferredHeight: 14
                                        radius: 2
                                        anchors.verticalCenter: parent.verticalCenter
                                        color: HusTheme.Primary.colorPrimary
                                    }
                                    HusText {
                                        Layout.fillWidth: false
                                        Layout.preferredWidth: implicitWidth
                                        text: modelData.label + Lang.tr('当前在线服务器 ','Current Online Servers ') + modelData.online
                                              + Lang.tr(' 台丨',' servers | ') + modelData.players + Lang.tr('个玩家在线',' players online')
                                        color: HusTheme.Primary.colorTextBase
                                        elide: Text.ElideRight
                                        font.pixelSize: 12
                                    }
                                }
                            }
                        }
                    }
                }



            }


            ColumnLayout {


                    Rectangle {
                        Layout.fillWidth: true
                        Layout.fillHeight: false

                        Layout.preferredHeight: communityStatCard.height
                        radius: 10
                        color: HusThemeFunctions.alpha(HusTheme.Primary.colorBgContainer, 0.45)
                        border.color: HusThemeFunctions.alpha(HusTheme.Primary.colorSplit, 0.5)
                        border.width: 1

                        ColumnLayout {
                            anchors.fill: parent
                            anchors.margins: 12
                            spacing: 4

                            HusText {
                                Layout.fillWidth: true
                                text: Lang.tr('各社区在线柱状图','Players by Community')
                                color: HusTheme.Primary.colorTextBase
                                font.pixelSize: 14
                                font.weight: Font.DemiBold
                            }

                            Item {
                                id: chartArea
                                Layout.fillWidth: true
                                Layout.fillHeight: true

                                property var rows: root.communityRows
                                property int maxVal: 1000


                                property var colors: ['#E5484D', '#F5B324', '#3B82F6', '#8B5CF6', '#22C55E', '#EC4899', '#F97316', '#06B6D4', '#94A3B8']
                                property real chartH: height - 22


                                Repeater {
                                    model: 6
                                    delegate: Item {
                                        y: chartArea.chartH * (5 - index) / 5
                                        Rectangle {
                                            x: 44
                                            width: chartArea.width - 44
                                            height: 1
                                            color: HusThemeFunctions.alpha(HusTheme.Primary.colorSplit, 0.25)
                                        }
                                        HusText {
                                            x: 0
                                            y: -5
                                            width: 28
                                            text: Math.round(chartArea.maxVal * index / 5)
                                            horizontalAlignment: Text.AlignRight
                                            color: HusTheme.Primary.colorTextSecondary
                                            font.pixelSize: 8
                                        }
                                    }
                                }


                                Repeater {
                                    model: chartArea.rows
                                    delegate: Item {
                                        id: bar
                                        width: chartArea.rows.length > 0 ? (chartArea.width - 44 - 3 * (chartArea.rows.length - 1)) / chartArea.rows.length : 0
                                        height: chartArea.chartH + 22
                                        x: 44 + index * (width + 3)
                                        property real barH: chartArea.maxVal > 0 ? Math.min(chartArea.chartH * modelData.players / chartArea.maxVal * 0.85, chartArea.chartH - 18) : 0
                                        property bool hovered: false


                                        MouseArea {
                                            anchors.horizontalCenter: parent.horizontalCenter
                                            y: 0
                                            width: Math.min(22, parent.width - 4)
                                            height: parent.height
                                            hoverEnabled: true
                                            onEntered: bar.hovered = true
                                            onExited: bar.hovered = false
                                        }


                                        Rectangle {
                                            anchors.horizontalCenter: parent.horizontalCenter
                                            anchors.bottom: parent.bottom
                                            anchors.bottomMargin: 22
                                            width: Math.min(22, parent.width - 4)
                                            height: bar.barH
                                            radius: 5
                                            color: chartArea.colors[index % chartArea.colors.length]
                                            opacity: bar.hovered ? 0.35 : 0
                                            Behavior on opacity { NumberAnimation { duration: 150 } }
                                        }
                                        Rectangle {
                                            anchors.horizontalCenter: parent.horizontalCenter
                                            anchors.bottom: parent.bottom
                                            anchors.bottomMargin: 22
                                            width: bar.hovered ? Math.min(18, parent.width - 4) : Math.min(14, parent.width - 4)
                                            height: bar.barH
                                            radius: 3
                                            color: bar.hovered ? Qt.lighter(chartArea.colors[index % chartArea.colors.length], 1.3) : chartArea.colors[index % chartArea.colors.length]
                                            Behavior on width { NumberAnimation { duration: 120; easing.type: Easing.OutCubic } }
                                            Behavior on color { ColorAnimation { duration: 120 } }
                                        }
                                        HusText {
                                            anchors.horizontalCenter: parent.horizontalCenter
                                            anchors.bottom: parent.bottom
                                            anchors.bottomMargin: bar.barH + 22 + 4
                                            text: modelData.players
                                            color: HusTheme.Primary.colorTextBase
                                            font.pixelSize: bar.hovered ? 12 : 8
                                            font.weight: bar.hovered ? Font.Bold : Font.Normal
                                            Behavior on font.pixelSize { NumberAnimation { duration: 120; easing.type: Easing.OutCubic } }
                                        }
                                        HusText {
                                            anchors.horizontalCenter: parent.horizontalCenter
                                            anchors.bottom: parent.bottom
                                            text: modelData.short || ''
                                            color: HusTheme.Primary.colorTextSecondary
                                            font.pixelSize: 8
                                        }
                                    }
                                }
                            }
                        }
                    }


                Layout.fillWidth: true
                Layout.fillHeight: true
                spacing: 12


            }
        }


        Rectangle {
            Layout.fillWidth: true
            Layout.fillHeight: true
            Layout.preferredHeight: 180
            radius: 10
            color: HusThemeFunctions.alpha(HusTheme.Primary.colorBgContainer, 0.45)
            border.color: HusThemeFunctions.alpha(HusTheme.Primary.colorSplit, 0.75)
            border.width: 1

            ColumnLayout {
                anchors.fill: parent
                anchors.margins: 14
                spacing: 6

                HusText {
                    text: Lang.tr('连接记录','Connection History')
                    color: HusTheme.Primary.colorTextBase
                    font.pixelSize: 14
                    font.weight: Font.DemiBold
                }

                ListView {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    spacing: 4
                    interactive: false
                    clip: true
                    model: (JoinHistoryManager.items || []).slice(0, 6)
                    delegate: Rectangle {
                        width: parent.width
                        height: 22
                        radius: 4

                        color: rowHover.containsMouse
                               ? HusThemeFunctions.alpha(HusTheme.Primary.colorBgContainer, 0.6)
                               : HusThemeFunctions.alpha(HusTheme.Primary.colorBgContainer, 0)

                        Behavior on color { ColorAnimation { duration: 180; easing.type: Easing.OutCubic } }
                        MouseArea {
                            id: rowHover
                            anchors.fill: parent
                            hoverEnabled: true
                            acceptedButtons: Qt.NoButton
                        }

                        RowLayout {
                            anchors.fill: parent
                            anchors.leftMargin: 4
                            anchors.rightMargin: 4
                            spacing: 8

                            Rectangle {
                                Layout.preferredWidth: 3
                                Layout.preferredHeight: 12
                                radius: 2
                                anchors.verticalCenter: parent.verticalCenter
                                color: HusTheme.Primary.colorPrimary
                            }
                            HusText {

                                Layout.fillWidth: true
                                text: homeMapTrans.formatMap(modelData.map)
                                color: HusTheme.Primary.colorTextBase
                                elide: Text.ElideRight
                                font.pixelSize: 12
                            }
                            HusText {

                                Layout.fillWidth: false
                                Layout.preferredWidth: 320
                                Layout.maximumWidth: 320
                                text: modelData.server
                                color: HusTheme.Primary.colorTextSecondary
                                elide: Text.ElideRight
                                font.pixelSize: 11
                            }
                            HusText {
                                Layout.preferredWidth: 46
                                horizontalAlignment: Text.AlignRight
                                text: modelData.count + Lang.tr(' 次',' joins')
                                color: HusTheme.Primary.colorTextSecondary
                                font.pixelSize: 11
                            }
                        }
                    }
                }

                HusText {
                    visible: (JoinHistoryManager.items || []).length === 0
                    text: Lang.tr('还没有连接记录，通过"加入"或"挤服"连接服务器后自动记录','No history yet; records appear after joining via "Join" or "Squeeze".')
                    color: HusTheme.Primary.colorTextSecondary
                    font.pixelSize: 11
                }
            }
        }

    }
}
