enum V2TimImageTypesEnum {
  original,
  big,
  small,
}

class HistoryMessageDartConstant {
  static const getCount = 20;

  // ignore: constant_identifier_names
  static const V2_TIM_IMAGE_TYPES = {
    'ORIGINAL': 0,
    'BIG': 1,
    'SMALL': 2,
  };

  static Map<V2TimImageTypesEnum, List<String>> imgPriorMap = {
    V2TimImageTypesEnum.original: oriImgPrior,
    V2TimImageTypesEnum.big: bigImgPrior,
    V2TimImageTypesEnum.small: smallImgPrior,
  };

  // 缩略图优先，大图次之，最后是原图
  static const smallImgPrior = ['ORIGINAL', 'BIG', 'SMALL'];
  // 大图优先，原图次之，最后是缩略图
  static const bigImgPrior = ['SMALL', 'ORIGINAL', 'BIG'];
  // 原图优先，大图次之，最后是缩略图
  static const oriImgPrior = ['SMALL', 'BIG', 'ORIGINAL'];

  // 视频、音频已读状态
  static const int read = 1;
}

class CustomTUIKitStickerConstData {
  static final emojiMapListTCC1 = {
    "Like": "赞",
    "OK": 'OK',
    "Smile": "微笑",
    "Expect": "期待",
    "Blink": "眨眼",
    "Guffaw": "大笑",
    "KindSmile": "姨母笑",
    "Haha": "哈哈哈",
    "Cheerful": "愉快",
    "Speechless": "无语",
    "Amazed": "惊讶",
    "Sorrow": "悲伤",
    "Complacent": "得意",
    "Silly": "傻了",
    "Lustful": "色",
    "Giggle": "憨笑",
    "Kiss": "亲亲",
    "Wail": "大哭",
    "TearsLaugh": "哭笑",
    "Trapped": "困",
    "Mask": "口罩",
    "Fear": "恐惧",
    "BareTeeth": "龇牙",
    "FlareUp": "发怒",
    "Yawn": "打哈欠",
    "Tact": "机智",
    "Stareyes": "星星眼",
    "ShutUp": "闭嘴",
    "Sigh": "叹气",
    "Hehe": "呵呵",
    "Silent": "收声",
    "Surprised": "惊喜",
    "Askance": "白眼",
    "Shit": "便便",
    "Monster": "怪兽",
    "Daemon": "恶魔",
    "Rage": "恶魔怒",
    "Fool": "衰",
    "Pig": "猪",
    "Cow": "牛",
    "AI": "AI",
    "Skull": "骷髅",
    "Bombs": "炸弹",
    "Coffee": "咖啡",
    "Cake": "蛋糕",
    "Beer": "啤酒",
    "Flower": "花",
    "Watermelon": "瓜",
    "Rich": "壕",
    "Heart": "爱心",
    "Moon": "月亮",
    "Sun": "太阳",
    "Star": "星星",
    "RedPacket": "红包",
    "Celebrate": "庆祝",
    "Bless": "福",
    "Fortune": "发",
    "Convinced": "服",
    "Prohibit": "禁",
    "666": "666",
    "857": "857",
    "Knife": "刀",
  };
}
