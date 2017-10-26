class Comfy::Cms::Fragment < ActiveRecord::Base
  self.table_name = 'comfy_cms_fragments'

  has_many_attached :attachments

  serialize :content

  # -- Callbacks ---------------------------------------------------------------
  after_save  :remove_attachments,
              :add_attachments

  # -- Relationships -----------------------------------------------------------
  belongs_to :page

  # -- Validations -------------------------------------------------------------
  validates :identifier,
    presence:   true,
    uniqueness: {scope: :page_id}

  # -- Instance Methods --------------------------------------------------------

  # Temporary accessor for uploaded files. We can only attach to persisted
  # records so we are deffering it to the after_save callback.
  # Note: hijacking dirty tracking to force trigger callbacks later.
  def files=(files)
    @files = [files].flatten.compact
    content_will_change! if @files.present?
  end

  def file_ids_destroy=(ids)
    @file_ids_destroy = [ids].flatten.compact
    content_will_change! if @file_ids_destroy.present?
  end

protected

  def remove_attachments
    return unless @file_ids_destroy.present?
    self.attachments.where(id: @file_ids_destroy).destroy_all
  end

  def add_attachments
    return if @files.blank?

    # If we're dealing with a single file
    if self.format == "file"
      @files = [@files.first]
      self.attachments.purge_later if self.attachments
    end

    self.attachments.attach(@files)
  end
end
