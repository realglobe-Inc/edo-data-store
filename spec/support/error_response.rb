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

def expect_ok(status_code: status_code, data: data)
  expect(response.status).to eq status_code
#  expect(response.body).to eq Oj.dump({status: :ok, data: data})
end

def expect_error(status_code: status_code, error_message: error_message)
  expect(response.status).to eq status_code
#  expect(response.body).to eq Oj.dump({status: :error, message: error_message})
end

def expect_200_ok(data: data)
  expect_ok(status_code: 200, data: data)
end

def expect_201_created(data: data)
  expect(response.status).to eq 201
  expect(response.body.blank?).to be true
end

def expect_204_no_content
  expect(response.status).to eq 204
  expect(response.body.blank?).to be true
end

def expect_403_error(error_message: error_message)
  expect_error(status_code: 403, error_message: error_message)
end

def expect_404_error(error_message: error_message)
  expect_error(status_code: 404, error_message: error_message)
end

def expect_409_error(error_message: error_message)
  expect_error(status_code: 409, error_message: error_message)
end
