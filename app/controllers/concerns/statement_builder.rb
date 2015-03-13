#--
# Copyright 2015 realglobe, Inc.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#++

module StatementBuilder
  extend ActiveSupport::Concern

  private

  def build_multipart_statement_response(statements)
    attachment_hashsums = statements.pluck(:attachments).flatten.map{|a| a["sha2"]}
    attachments = Attachment.where(:sha2.in => attachment_hashsums)
    boundary = rand(36**16).to_s(36)
    body = [] <<
      "--#{boundary}" <<
      "Content-Type: application/json" <<
      "" <<
      Oj.dump(statements.map(&:properties))
    attachments.each do |attachment|
      body <<
        "--#{boundary}" <<
        attachment.multipart_response_format
    end
    body << "--#{boundary}--"
    response_body = body.join("\r\n")
    ["multipart/mixed; boundary=#{boundary}", response_body]
  end
end
