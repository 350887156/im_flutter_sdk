import 'package:flutter/material.dart';

import 'package:im_flutter_sdk/im_flutter_sdk.dart';

import 'chat_page.dart';
import 'items/conversation_list_item.dart';
import 'package:im_flutter_sdk_example/utils/style.dart';
import 'package:im_flutter_sdk_example/utils/localizations.dart';
import 'package:im_flutter_sdk_example/utils/theme_util.dart';
import 'package:im_flutter_sdk_example/common/common.dart';
import 'package:im_flutter_sdk_example/utils/widget_util.dart';

class EMConversationListPage extends StatefulWidget{

  @override
  State<StatefulWidget> createState() {
    // TODO: implement createState
    return _EMConversationListPageState();
  }
}

class _EMConversationListPageState extends State<EMConversationListPage>
    implements EMMessageListener,
        EMConnectionListener,
    EMConversationListItemDelegate{
    var conList = List<EMConversation>();
    var sortMap = Map<String, EMConversation>();
    bool _isConnected = EMClient.getInstance().isConnected();
    String errorText;

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    EMClient.getInstance().chatManager().addMessageListener(this);
    EMClient.getInstance().addConnectionListener(this);
    loadEMConversationList();
  }

  @override
  void dispose() {
    // TODO: implement dispose
    super.dispose();
    EMClient.getInstance().chatManager().removeMessageListener(this);
    EMClient.getInstance().removeConnectionListener(this);
  }

  void loadEMConversationList() async{
    int i = 0;
    sortMap.clear();
    Map map = await EMClient.getInstance().chatManager().getAllConversations();
    map.forEach((k, v) async{
      var conversation = v as EMConversation;
      EMMessage message = await conversation.getLastMessage();
      sortMap.putIfAbsent(message.msgTime,() => v);
      i++;
      if(i == map.length){
        _refreshUI();
      }
    });
  }

  void _refreshUI() {
    setState(() {});
  }

  Widget _buildConversationListView(){
    return ListView.builder(
        shrinkWrap: true,
        physics:NeverScrollableScrollPhysics(),
        scrollDirection: Axis.vertical,
        itemCount: conList.length + 1,
        itemBuilder: (BuildContext context,int index){
          if(index == 0){
            return _buildErrorItem();
          }
          if(conList.length <= 0){
            return WidgetUtil.buildEmptyWidget();
          }
          return EMConversationListItem(conList[index - 1], this);
        }
    );
  }

  Widget _buildErrorItem(){
    return Visibility(
        visible: !_isConnected,
        child:Container(
          height: 30.0,
          color: ThemeUtils.isDark(context) ? EMColor.darkRed : EMColor.red,
          child: Center(child : Text(DemoLocalizations.of(context).unableConnectToServer, style: TextStyle(color : ThemeUtils.isDark(context) ? EMColor.darkText : EMColor.text),)),
        )
    );
  }

  Widget _buildSearchBar(){
    return InkWell(
      onTap: (){
        print('search');
      },
      child : Stack(children: <Widget>[
          Container(height: EMLayout.emSearchBarHeight, color: ThemeUtils.isDark(context) ? EMColor.darkBgColor : EMColor.bgColor,),
          Container(
            padding: EdgeInsets.only(left: 8.0),
            margin: EdgeInsets.only(right: 8.0, left: 8.0),
            height: EMLayout.emSearchBarHeight,
            decoration:  BoxDecoration(
              color: ThemeUtils.isDark(context)? EMColor.darkBgSearchBar : EMColor.bgSearchBar,
              borderRadius: BorderRadius.all(Radius.circular(EMLayout.emSearchBarHeight/2)),
              border: Border.all(width: 1, color: ThemeUtils.isDark(context) ? EMColor.darkBgSearchBar : EMColor.bgSearchBar),
            ),
            child:Row(
              children: <Widget>[
                Icon(Icons.search),
                Text(DemoLocalizations.of(context).search, style: TextStyle(color: ThemeUtils.isDark(context)? EMColor.darkText : EMColor.text),),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void sortConversation(){
    if(sortMap.length > 0) {

      List sortKeys = sortMap.keys.toList();
      // key排序
      sortKeys.sort((a, b) => b.compareTo(a));
      sortKeys.forEach((k) {
        var v = sortMap.putIfAbsent(k, null);
        conList.add(v);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    sortConversation();
    // TODO: implement build
    return new Scaffold(
      appBar: AppBar(
        elevation: 0,
        centerTitle : true,
        backgroundColor: ThemeUtils.isDark(context) ? EMColor.darkAppMain : EMColor.appMain,
        title: Text(DemoLocalizations.of(context).conversation, style: TextStyle(fontSize: EMFont.emAppBarTitleFont, color: ThemeUtils.isDark(context) ? EMColor.darkText : EMColor.text)),
        leading: Icon(null),
        actions: <Widget>[
          Icon(Icons.add,),
          SizedBox(width: 24,)
        ],
      ),
      key: UniqueKey(),
      body:SingleChildScrollView(
        child:Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            _buildSearchBar(),
            _buildConversationListView(),
          ],
        ),
      ),
    );
  }
    /// 连接监听
  void onConnected(){
    print('onConnected');
    _isConnected = true;
    _refreshUI();
  }
  void onDisconnected(int errorCode){
    print('onDisconnected');

    _isConnected = false;
    _refreshUI();
  }

  /// 消息监听
  void onMessageReceived(List<EMMessage> messages){
    loadEMConversationList();
  }
  void onCmdMessageReceived(List<EMMessage> messages){}
  void onMessageRead(List<EMMessage> messages){}
  void onMessageDelivered(List<EMMessage> messages){}
  void onMessageRecalled(List<EMMessage> messages){}
  void onMessageChanged(EMMessage message, Object change){}
  void _deleteConversation(EMConversation conversation) async{
    bool result = await EMClient.getInstance().chatManager().deleteConversation(userName: conversation.conversationId, deleteMessages: true);
    if(result == false){
      print('deleteConversation failed');
    }
    loadEMConversationList();
  }

  void _clearConversationUnread(EMConversation conversation){
    conversation.markAllMessagesAsRead();
    loadEMConversationList();
  }

  /// 点击事件
  void onTapConversation(EMConversation conversation){
      Navigator.push(context, new MaterialPageRoute(builder: (BuildContext context){
          return new ChatPage(arguments: {'mType': getType(conversation.type),'toChatUsername':conversation.conversationId});
      }));
  }

  int getType(EMConversationType type){
    switch(type){
      case EMConversationType.Chat:
        return Constant.chatTypeSingle;
      case EMConversationType.GroupChat:
        return Constant.chatTypeGroup;
      case EMConversationType.ChatRoom:
        return Constant.chatTypeChatRoom;
      default:
        return Constant.chatTypeSingle;
    }
  }

  /// 长按事件
  void onLongPressConversation(EMConversation conversation,Offset tapPos){
    Map<String,String> actionMap = {
      Constant.deleteConversationKey:DemoLocalizations.of(context).deleteConversation,
      Constant.clearUnreadKey:DemoLocalizations.of(context).clearUnread,
    };
    WidgetUtil.showLongPressMenu(context, tapPos,actionMap,(String key){
      if(key == "DeleteConversationKey") {
        _deleteConversation(conversation);
      }else if(key == "ClearUnreadKey") {
        _clearConversationUnread(conversation);
      }
    });
  }

}