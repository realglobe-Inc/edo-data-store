def expect_ok(status_code: status_code, data: data)
  expect(response.status).to eq status_code
  expect(response.body).to eq Oj.dump({status: :ok, data: data})
end

def expect_error(status_code: status_code, error_message: error_message)
  expect(response.status).to eq status_code
  expect(response.body).to eq Oj.dump({status: :error, message: error_message})
end

def expect_200_ok(data: data)
  expect_ok(status_code: 200, data: data)
end

def expect_201_ok(data: data)
  expect_ok(status_code: 201, data: data)
end

def expect_403_error(error_message: error_message)
  expect_error(status_code: 403, error_message: error_message)
end

def expect_404_error(error_message: error_message)
  expect_error(status_code: 404, error_message: error_message)
end
