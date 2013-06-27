Didh.Views.Frontend ||= {}

class Didh.Views.Frontend.SingleCommentView extends Backbone.View

  template: JST["backbone/templates/frontend/comment"]

  tagName: 'li'
  className: 'comment-drawer--comment'
  loadedViews: new Array

  events: {
    'click .js-action-reply': 'toggleReply'
    'click .js-action-remove': 'deleteComment'
  }

  deleteComment: (e) ->
    if e?
      e.preventDefault()
      e.stopPropagation()
    @model.destroy()

  toggleReply: (e) ->
    if e?
      e.preventDefault()
      e.stopPropagation()
    if @$el.hasClass('active')
      @$el.removeClass('active')
    else
      @$el.addClass('active')

  initialize: (options) ->
    @id = @model.id
    @render()

  onRemove: () ->
    _.each(@loadedViews, (view) =>
      view.remove()
      view.unbind()
# TODO: fix recursive garbage collection
#      if view.onRemove then view.onRemove()
    )

  render: () ->
    $(@el).html(@template({model: @model}))

    comments = @collection.where({parent_id: @model.id})
    if comments.length > 0
      $container = @$el.find('.js-comment-container:first')
      _.each(comments, (comment) =>
        child = new Didh.Views.Frontend.SingleCommentView({model: comment, collection: @collection})
        @loadedViews.push child
        $container.append(child.$el)
      )




class Didh.Views.Frontend.CommentsView extends Backbone.View

  template: JST["backbone/templates/frontend/comments"]
  events: {
    'click .js-comment-close':  'close'
    'submit form': 'saveComment'
  }

  saveComment: (e) ->
    if e? then e.preventDefault()
    $target = $(e.target)
    body = $target.find('textarea').val()
    if $target.data().parent then parent = $target.data().parent else parent = null
    comment = new Didh.Models.Comment({
      body: body
      sentence_checksum: @currentSentenceId
      text_id: @currentTextId
      parent_id: parent
    })
    comment.save({}, {
      success: () =>
        @collection.add(comment)
        $target.find('textarea').val('')
    })

  open: (textId, sentenceId) ->
    @currentSentenceId = sentenceId
    @currentTextId = textId
    @collection.textId = @currentTextId
    params = {data: {sentence: sentenceId}}
    console.log params
    @collection.fetch(params)
    @$el.removeClass('open')
    @$el.addClass('open')

  close: (e) ->
    if e? then e.preventDefault()
    @$el.removeClass('open')

  initialize: () ->
    @loadedViews = []
    @collection = new Didh.Collections.CommentsCollection()

    @collection.bind('add', () =>
        @render()
    )

    @collection.bind('remove', () =>
        @render()
    )

    @collection.bind('reset', () =>
      @render()
    )

  render: (template) ->
    console.log @collection

    _.each(@loadedViews, (view) =>
        view.remove()
        view.unbind()
        if view.onRemove then view.onRemove()
    )
    @loadedViews = []

    comments = @collection.where({parent_id: false})

    selector = "#sentence-#{@currentSentenceId}"
    @currentSentenceText = $(selector).html()

    $(@el).html(@template({reference: @currentSentenceText}))

    comments = @collection.where({parent_id: null})
    container = @$el.find('.js-comment-container:first')
    _.each(comments, (comment) =>
      child = new Didh.Views.Frontend.SingleCommentView({model: comment, collection: @collection})
      @loadedViews.push child
      container.append(child.$el)
    )

    @$el.find('textarea').autosize()


#
#    selector = "#sentence-#{@currentSentenceId}"
#    @currentSentenceText = $(selector).html()
#
#    out
