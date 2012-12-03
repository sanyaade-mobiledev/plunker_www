module = angular.module("plunker.panes")

module.requires.push "plunker.url"
module.requires.push "plunker.session"


module.run [ "$q", "$http", "url", "panes", "session", ($q, $http, url, panes, session) ->

  debounce = (wait, func, immediate) ->
    timeout = undefined
    ->
      context = @
      args = arguments
      later = ->
        timeout = null
        unless immediate then func.apply(context, args)
      if immediate and not timeout then func.apply(context, args)
      clearTimeout(timeout)
      timeout = setTimeout(later, wait)

  panes.add
    id: "preview"
    icon: "eye-open"
    title: "Preview your work"
    template: """
      <div class="plunker-previewer" ng-class="{loading: loading}">
        <div class="plunker-previewer-ops">
          <div class="btn-toolbar">
            <div class="btn-group" ng-switch on="windowed">
              <button id="refresh-preview" ng-click="refreshPreview()" class="btn btn-mini btn-success" title="Manually trigger a refresh of the preview"><i class="icon-refresh icon-white"></i></button>
              <button id="expand-preview" ng-click="expandWindow()" ng-switch-when="false" class="btn btn-mini btn-primary" title="Launch the preview in a separate window"><i class="icon-fullscreen icon-white"></i></button>
              <button id="expand-preview" ng-click="contractWindow()" ng-switch-when="true" class="btn btn-mini btn-danger" title="Close the child preview window"><i class="icon-remove icon-white"></i></button>
            </div>
          </div>
        </div>
        <iframe class="plunker-previewer-iframe" frameborder="0" width="100%" height="100%" scrolling="auto"></iframe>
      </div>
    """
    link: ($scope, $el, attrs) ->
      previewId = ""
      refreshQueued = false
      pane = @
      
      $previewer = $("iframe.plunker-previewer-iframe", $el)
      
      $scope.session = session
      $scope.windowed = false
      
      $scope.refreshPreview = ->
        dfd = $q.defer()
        json = files: session.toJSON().files
        
        $scope.loading = true
        
        req = $http.post("#{url.run}/#{previewId}", json, cache: false)
        
        req.then (res) ->
          loc = $previewer[0].contentWindow.location
          
          if loc is res.data.run_url
            loc.reload(true)
          else
            loc.replace(res.data.run_url)
  
          $previewer.ready ->
            dfd.resolve()
            $scope.loading = false
  
          previewId = res.data.id
        , (err) ->
          dfd.reject(err)
          $scope.loading = false
          
        return $scope.promise = dfd.promise
      
      $scope.$watch "session.updated_at", debounce 400, ->
        $scope.refreshPreview() if pane.active
        
      $scope.$watch "pane.active"
]