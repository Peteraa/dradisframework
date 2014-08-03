# The UploadController provides access to the different upload plugins that 
# have been deployed in the dradis server.
#

module Dradis
  module Frontend

    class UploadController < Dradis::Frontend::AuthenticatedController
      before_filter :find_nodes
      before_filter :find_plugins


      layout 'dradis/themes/snowcrash'

      # include Plugins::Upload
      # before_filter :validate_uploader, :only => [:import, :create, :parse]
      # after_filter :wrap_ajax_file_upload_response, :only => [:create]
      #
      # private
      # # Ensure that the requested :uploader is valid and has been included in the
      # # Plugins::Upload mixin
      # def validate_uploader()
      #   valid_uploaders = Plugins::Upload::included_modules.collect(&:name)
      #   if (params.key?(:uploader) && valid_uploaders.include?(params[:uploader]))
      #     @uploader = params[:uploader].constantize
      #   else
      #     redirect_to '/'
      #   end
      # end
      #
      # def wrap_ajax_file_upload_response
      #   if request.content_type == 'multipart/form-data' && request.format == :js
      #     response.content_type = nil
      #     response.body = "<textarea>#{response.body}</textarea>"
      #   end
      # end
      #
      # public
      def index
        @last_job = Dradis::Core::Log.maximum(:uid) || 1
      end
      #
      # # This method provides a list of all the available uploader plugins. It
      # # assumes that each export plugin inclides instance methods in the
      # # Plugins::Upload mixing.
      # def list
      #   respond_to do |format|
      #     format.html{ redirect_to '/' }
      #     format.json{
      #       list = []
      #       Plugins::Upload.included_modules.reverse.each do |plugin|
      #         list << {
      #           :name => plugin.name.underscore.humanize.gsub(/\//,' - '),
      #           :plugin => plugin.name
      #         }
      #       end
      #
      #       render :json => list
      #     }
      #   end
      # end
      #
      # # This method handles the execution flow to the requested :uploader. It first
      # # copies the uploaded file into the configured uploads node (see
      # # Configuration.uploadsNode). Then the request is passed to the chosen plugin.
      # def import
      #   # create an 'Imported files' node
      #   # we need to use ::Configuration to get a global setting, otherwise the
      #   # Configuration object will be used in the context of the upload plugin
      #   # (e.g. WxfUpload::Configuration) and the global setting won't be found
      #   uploadsNode = Node.find_or_create_by_label(::Configuration.uploadsNode)
      #
      #   # add the file as an attachment
      #   attachment = Attachment.new( params[:file].original_filename, :node_id => uploadsNode.id )
      #   attachment << params[:file].read
      #   attachment.save
      #
      #   #Increment revision. Remember to use the ActiveRecord base Configuration object
      #   ::Configuration.increment_revision
      #
      #   # process the upload using the plugin
      #   begin
      #     @uploader.import(:file => attachment.fullpath)
      #
      #     # Notify the caller that everything was fine
      #     render :text => { :success=>true }.to_json
      #
      #   rescue Exception => e
      #     # Something went wrong
      #     logger.error e, e.backtrace
      #     render :text => { :success => false, :error => CGI::escape(e.message), :backtrace => e.backtrace.collect{ |line| CGI::escape(line) } }.to_json
      #   end
      # end
      #
      def create
        # TODO: this would overwrite an existing file with the same name.
        # See AttachmentsController#create

        # save a copy of the uploaded file
        uploads_node = Dradis::Core::Configuration.plugin_uploads_node
        filename = params[:file].original_filename

        # add the file as an attachment
        @attachment = Dradis::Core::Attachment.new(filename, node_id: uploads_node.id)
        @attachment << params[:file].read
        @attachment.save

        @success = true
        flash.now[:notice] = "Successfully uploaded #{filename}"
      end
      #
      # def parse
      #   item_id = params[:item_id]
      #   uploadsNode = Node.find_or_create_by_label(::Configuration.uploadsNode)
      #   attachment = Attachment.find(params[:file], :conditions => { :node_id => uploadsNode.id })
      #
      #   if File.size(attachment.fullpath) < 1024*1024
      #     logger = Log.new(:uid => item_id)
      #     logger.write('Small attachment detected. Processing in line.')
      #     begin
      #       @uploader.import(:file => attachment.fullpath, :logger => logger)
      #     rescue Exception => e
      #       logger.write('There was a fatal error processing your upload:')
      #       logger.write(e.message)
      #     end
      #     logger.write('Worker process completed.')
      #   else
      #     Log.new(:uid => item_id).write("Enqueueing job to start in the background. Job id is #{item_id}")
      #     Bj.submit "ruby script/rails runner lib/upload_processing_job.rb %s \"%s\" %s" % [ params[:uploader], attachment.fullpath, params[:item_id] ]
      #   end
      # end
      #
      # def status
      #   @logs = Log.find(:all, :conditions => [ 'uid = ? and id > ?', params[:item_id], params[:after].to_i ] )
      #   @uploading = !(@logs.last.text == 'Worker process completed.') if @logs.any?
      # end

      private

      # There should be a better way of handling this.
      def find_nodes
        @nodes = Dradis::Core::Node.includes(:children).all
        @new_node = Dradis::Core::Node.new
      end

      # The list of available Upload plugins. See the dradis_plugins gem.
      def find_plugins
        @plugins = Dradis::Plugins::with_feature(:upload).collect do |plugin|
          path = plugin.to_s
          path[0..path.rindex('::')-1].constantize
        end        
      end
    end

  end
end