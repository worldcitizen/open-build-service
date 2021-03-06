# -*- coding: utf-8 -*-
require_relative '../../test_helper'

class Webui::PackageBranchTest < Webui::IntegrationTest

  uses_transaction :test_branch_package_for_global_project
  uses_transaction :test_branch_package_double_and_submit_back
  uses_transaction :test_branch_package_for_home_project
  uses_transaction :test_branch_package_twice

  def create_package_branch new_branch
    click_link 'Branch existing package'

    page.must_have_text "Add New Package Branch to #{@project}"
    page.must_have_text 'Name of original project:'
    page.must_have_text 'Name of package in original project:'
    page.must_have_text 'RemoteInstance'
    assert page.current_url =~ %r{/project/new_package_branch}

    new_branch[:expect]           ||= :success
    new_branch[:name]             ||= ''
    new_branch[:original_name]    ||= ''
    new_branch[:original_project] ||= ''

    fill_in 'linked_project', with: new_branch[:original_project]
    fill_in 'linked_package', with: new_branch[:original_name]
    fill_in 'target_package', with: new_branch[:name]

    click_button 'Create Branch'

    if new_branch[:expect] == :success
      flash_message.must_equal "Branched package #{@project} / #{new_branch[:name]}"
      flash_message_type.must_equal :info
      assert page.current_url.end_with? package_show_path(project: @project, package: new_branch[:name])
    elsif new_branch[:expect] == :invalid_package_name
      flash_message.must_equal "Invalid package name: '#{new_branch[:original_name]}'"
      flash_message_type.must_equal :alert
    elsif new_branch[:expect] == :invalid_project_name
      flash_message.must_equal "Invalid project name: '#{new_branch[:original_project]}'"
      flash_message_type.must_equal :alert
    elsif new_branch[:expect] == :already_exists
      flash_message.must_equal "Package '#{new_branch[:name]}' already exists in project '#{@project}'"
      flash_message_type.must_equal :alert
    else
      throw 'Invalid value for argument <expect>.'
    end
  end

  def setup
    @project = 'home:Iggy'
    super
  end

  def test_branch_package_for_home_project

    login_Iggy to: project_show_path(:project => @project)

    create_package_branch(
      :name => 'TestPack_link',
      :original_name => 'TestPack',
      :original_project => 'home:Iggy')
  end

  def test_branch_package_double_and_submit_back
    use_js

    login_Iggy to: project_show_path(:project => @project)

    create_package_branch(
      :name => 'TestPack_link',
      :original_name => 'TestPack',
      :original_project => 'home:Iggy')
    Suse::Backend.put('/source/home:Iggy/TestPack_link/new_file', "test 1")

    visit project_show_path(:project => @project)
    create_package_branch(
      :name => 'TestPack_double_branch',
      :original_name => 'TestPack_link',
      :original_project => 'home:Iggy')
    Suse::Backend.put('/source/home:Iggy/TestPack_double_branch/new_file', "test 2")

    # submit
    click_link 'Submit package'
    fill_in 'description', with: 'one way back'
    click_button 'Ok'
    within '#flash-messages' do
      click_link 'submit request'
    end
    requestid = current_path.gsub(%r{\/request\/show\/(\d*)}, '\1').to_i

    # accept with forward
    visit request_show_path(requestid)
    check('forward_link')
    click_button 'Accept'
    flash_message.must_have_text "accepted and forwarded"

    # cleanup
    delete_package("home:Iggy", "TestPack_link")
  end

  def test_branch_package_for_global_project

    login_Iggy to: project_show_path(:project => @project)

    create_package_branch(
      :name => 'PublicPackage1',
      :original_name => 'kdelibs',
      :original_project => 'kde4')
  end


  def test_branch_package_twice_duplicate_name

    login_Iggy to: project_show_path(:project => @project)

    create_package_branch(
      :expect => :already_exists,
      :name => 'TestPack',
      :original_name => 'TestPack',
      :original_project => 'home:Iggy')
  end


  def test_branch_package_twice

    login_Iggy to: project_show_path(:project => @project)

    create_package_branch(
      :name => 'TestPack2',
      :original_name => 'kdelibs',
      :original_project => 'kde4')
    visit project_show_path(:project => @project)
    create_package_branch(
      :name => 'TestPack3',
      :original_name => 'kdelibs',
      :original_project => 'kde4')
  end


  def test_branch_empty_package_name

    login_Iggy to: project_show_path(:project => @project)

    create_package_branch(
      :name => '',
      :original_name => '',
      :original_project => 'home:Iggy',
      :expect => :invalid_package_name)
  end

  def test_branch_empty_project_name

    login_Iggy to: project_show_path(:project => @project)

    create_package_branch(
      :name => 'TestPack',
      :original_name => 'TestPack',
      :original_project => '',
      :expect => :invalid_project_name)
  end

  def test_branch_package_name_with_spaces

    login_Iggy to: project_show_path(:project => @project)

    create_package_branch(
      :name => 'BranchedPackage',
      :original_name => 'invalid package name',
      :original_project => 'home:Iggy',
      :expect => :invalid_package_name)
  end


  def test_branch_project_name_with_spaces

    login_Iggy to: project_show_path(:project => @project)

    create_package_branch(
      :name => 'BranchedPackage',
      :original_name => 'SomePackage',
      :original_project => 'invalid project name',
      :expect => :invalid_project_name)
  end

  def test_autocomplete_packages
    use_js

    login_Iggy to: project_show_path(:project => @project)
    click_link 'Branch existing package'

    results = fill_autocomplete 'linked_project', with: 'home:d', select: 'home:dmayr'
    results.must_include 'home:dmayr'
    results.wont_include 'Apache'
    results = fill_autocomplete 'linked_package', with: 'x11', select: 'x11vnc'
    results.must_equal %w(x11vnc)

    click_button 'Create Branch'
    page.must_have_text "Branched package home:Iggy / x11vnc"
    page.must_have_text "Links to home:dmayr / x11vnc"
  end

end
