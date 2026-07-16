module AcademyHelper
  ACADEMY_CONTENT_ROOT = Rails.root.join("config/data/posturacorretta/accademia")

  def academy_teacher(teachers, slug)
    teachers.to_h.fetch(slug)
  end

  def academy_location(locations, slug)
    locations.to_h.fetch(slug)
  end

  def academy_markdown(content_path)
    full_path = ACADEMY_CONTENT_ROOT.join(content_path.to_s).cleanpath
    return "".html_safe unless full_path.to_s.start_with?(ACADEMY_CONTENT_ROOT.to_s)
    return "".html_safe unless full_path.file?

    markdown(full_path.read)
  end

  def academy_mode_label(mode)
    {
      "info" => "Informati",
      "practice" => "Pratica",
      "teach" => "Insegna"
    }.fetch(mode.to_s, mode.to_s)
  end

  def academy_teacher_avatar(teacher, extra_class: "")
    initials = teacher.fetch("name").split.map { |part| part[0] }.join

    button_tag(
      type: "button",
      class: "avatar teacher-#{teacher.fetch('category')} #{extra_class}",
      data: { modal_template: "teacher-#{teacher.fetch('slug')}" },
      aria: { label: "Apri il profilo di #{teacher.fetch('name')}" }
    ) do
      image_tag(
        teacher.fetch("img"),
        alt: "",
        onerror: "this.style.display='none';this.parentNode.textContent='#{j(initials)}'"
      )
    end
  end
end
